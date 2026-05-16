#!/usr/bin/env python3
"""
Genera .reports/test-report.md a partir de los artefactos producidos por los
3 tiers de tests:

  - DB:  .reports/db.log + códigos de retorno
  - BE:  movieService/target/surefire-reports/TEST-*.xml
  - FE:  .reports/fe-junit.xml (o frontend/junit.xml)

No requiere dependencias externas (solo stdlib).

Uso:
  python3 generate-report.py <repo_root>
"""

import json
import os
import re
import sys
import subprocess
import socket
from datetime import datetime
from pathlib import Path
import xml.etree.ElementTree as ET


# ---------- helpers ----------

def safe_run(cmd):
    try:
        return subprocess.check_output(cmd, shell=False, stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return "n/a"


def load_exit_codes(reports_dir: Path):
    f = reports_dir / "exit-codes.json"
    if f.exists():
        try:
            return json.loads(f.read_text())
        except Exception:
            pass
    return {"db": -1, "be": -1, "fe": -1}


# ---------- DB parser ----------

DB_RESULT_RE = re.compile(r">>>\s*RESULT:\s+(\S+)\s+(PASS|FAIL)")
DB_SUMMARY_RE = re.compile(r">>>\s*SUMMARY DB:\s*total=(\d+)\s+pass=(\d+)\s+fail=(\d+)")


def parse_db(reports_dir: Path):
    log = reports_dir / "db.log"
    results = {}        # nombre -> "PASS"|"FAIL"
    summary = {"total": 0, "pass": 0, "fail": 0, "duration": "n/a"}
    if not log.exists():
        return results, summary
    text = log.read_text(errors="replace")
    for name, status in DB_RESULT_RE.findall(text):
        results[name] = status
    m = DB_SUMMARY_RE.search(text)
    if m:
        summary["total"] = int(m.group(1))
        summary["pass"] = int(m.group(2))
        summary["fail"] = int(m.group(3))
    return results, summary


# ---------- BE parser (Surefire) ----------

def parse_surefire(surefire_dir: Path):
    cases = []  # list of dicts: {class, method, status, time_ms}
    if not surefire_dir.exists():
        return cases, {"total": 0, "pass": 0, "fail": 0, "skip": 0, "duration": 0.0, "failure_snippet": ""}
    totals = {"total": 0, "pass": 0, "fail": 0, "skip": 0, "duration": 0.0}
    failure_snippets = []
    for xml in sorted(surefire_dir.glob("TEST-*.xml")):
        try:
            root = ET.parse(xml).getroot()
        except ET.ParseError:
            continue
        for tc in root.iter("testcase"):
            class_name = tc.attrib.get("classname", "")
            method = tc.attrib.get("name", "")
            time_s = float(tc.attrib.get("time", "0") or 0)
            failure = tc.find("failure")
            error = tc.find("error")
            skipped = tc.find("skipped")
            if failure is not None or error is not None:
                status = "FAIL"
                totals["fail"] += 1
                msg = (failure.text or error.text or "")[:500]
                failure_snippets.append(f"[{class_name}.{method}]\n{msg.strip()}")
            elif skipped is not None:
                status = "SKIP"
                totals["skip"] += 1
            else:
                status = "PASS"
                totals["pass"] += 1
            totals["total"] += 1
            totals["duration"] += time_s
            cases.append({
                "class": class_name.split(".")[-1],
                "method": method,
                "status": status,
                "time_ms": int(round(time_s * 1000)),
            })
    snippet = "\n\n".join(failure_snippets[:5]) if failure_snippets else "(sin fallos)"
    totals["failure_snippet"] = snippet[:4000]
    return cases, totals


# ---------- FE parser (jest-junit XML) ----------

def parse_jest_junit(xml_path: Path):
    cases = []
    totals = {"total": 0, "pass": 0, "fail": 0, "skip": 0, "duration": 0.0, "failure_snippet": ""}
    if not xml_path.exists():
        return cases, totals
    try:
        root = ET.parse(xml_path).getroot()
    except ET.ParseError:
        return cases, totals
    failure_snippets = []
    for ts in root.iter("testsuite"):
        suite_file = ts.attrib.get("file", ts.attrib.get("name", ""))
        for tc in ts.iter("testcase"):
            class_name = tc.attrib.get("classname", "")
            method = tc.attrib.get("name", "")
            time_s = float(tc.attrib.get("time", "0") or 0)
            failure = tc.find("failure")
            skipped = tc.find("skipped")
            if failure is not None:
                status = "FAIL"
                totals["fail"] += 1
                msg = (failure.text or "")[:500]
                failure_snippets.append(f"[{method}]\n{msg.strip()}")
            elif skipped is not None:
                status = "SKIP"
                totals["skip"] += 1
            else:
                status = "PASS"
                totals["pass"] += 1
            totals["total"] += 1
            totals["duration"] += time_s
            cases.append({
                "file": suite_file,
                "name": method,
                "class": class_name,
                "status": status,
                "time_ms": int(round(time_s * 1000)),
            })
    totals["failure_snippet"] = "\n\n".join(failure_snippets[:5]) if failure_snippets else "(sin fallos)"
    return cases, totals


# ---------- BE/FE lookups por id de caso ----------

BE_TC_MAP = {
    "TC-BE-01": ("MovieServiceImplTest", "getAllDisplayingMoviesInVision_returnsDaoResult"),
    "TC-BE-02": ("MovieServiceImplTest", "getAllComingSoonMovies_returnsDaoResult"),
    "TC-BE-03": ("MovieServiceImplTest", "getMovieByMovieId_returnsDto"),
    "TC-BE-04": ("MovieServiceImplTest", "getMovieByMovieId_returnsNullWhenDaoReturnsNull"),
    "TC-BE-05": ("MovieControllerTest", "getDisplayingMovies"),
    "TC-BE-06": ("MovieControllerTest", "getComingSoonMovies"),
    "TC-BE-07": ("MovieControllerTest", "getMovieById"),
}

FE_TC_MAP = {
    # match por substring del "name" del testcase
    "TC-FE-01": "getAllDisplayingMovies hace GET al endpoint correcto",
    "TC-FE-02": "getMovieById concatena el id en la URL",
    "TC-FE-03": "getAllComingSoonMovies usa el endpoint comingSoonMovies",
    "TC-FE-04": "MainPage renderiza los nombres de películas",
    "TC-FE-05": "DetailPage renderiza nombre, director y sinopsis",
}


def find_be_case(cases, cls, method):
    for c in cases:
        if c["class"] == cls and method in c["method"]:
            return c
    return None


def find_fe_case(cases, needle):
    for c in cases:
        if needle.lower() in c["name"].lower():
            return c
    return None


# ---------- render ----------

def render(template_text, ctx):
    out = template_text
    for k, v in ctx.items():
        out = out.replace(f"<<{k}>>", str(v))
    # Cualquier placeholder no resuelto se vuelve "n/a"
    out = re.sub(r"<<[A-Z0-9_]+>>", "n/a", out)
    return out


def main():
    repo = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    reports_dir = repo / ".reports"
    reports_dir.mkdir(exist_ok=True)
    template_path = repo / "lab1-unit-testing" / "report-template.md"
    if not template_path.exists():
        print(f"[!] No encuentro la plantilla en {template_path}", file=sys.stderr)
        sys.exit(2)
    template = template_path.read_text()

    # --- DB ---
    db_results, db_totals = parse_db(reports_dir)

    # --- BE ---
    be_cases, be_totals = parse_surefire(repo / "movieService" / "target" / "surefire-reports")

    # --- FE ---
    fe_xml = reports_dir / "fe-junit.xml"
    if not fe_xml.exists():
        fe_xml = repo / "frontend" / "junit.xml"
    fe_cases, fe_totals = parse_jest_junit(fe_xml)

    exit_codes = load_exit_codes(reports_dir)
    db_status = "PASS" if exit_codes.get("db") == 0 else "FALLÓ"
    be_status = "PASS" if exit_codes.get("be") == 0 else "FALLÓ"
    fe_status = "PASS" if exit_codes.get("fe") == 0 else "FALLÓ"
    global_ok = all(exit_codes.get(k) == 0 for k in ("db", "be", "fe"))
    verdict = "LISTO PARA PRESENTACIÓN" if global_ok else "REVISAR FALLAS"

    ctx = {
        "TIMESTAMP_UTC": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "GIT_BRANCH": safe_run(["git", "-C", str(repo), "rev-parse", "--abbrev-ref", "HEAD"]),
        "GIT_SHORT_SHA": safe_run(["git", "-C", str(repo), "rev-parse", "--short", "HEAD"]),
        "HOSTNAME": socket.gethostname(),
        "DOCKER_VERSION": safe_run(["docker", "--version"]),
        "COMPOSE_VERSION": safe_run(["docker", "compose", "version"]),
        # Resumen global
        "DB_STATUS": db_status, "DB_PASS": db_totals["pass"], "DB_FAIL": db_totals["fail"],
        "DB_SKIP": 0, "DB_DURATION": db_totals.get("duration", "n/a"),
        "BE_STATUS": be_status, "BE_PASS": be_totals["pass"], "BE_FAIL": be_totals["fail"],
        "BE_SKIP": be_totals["skip"], "BE_DURATION": f"{be_totals['duration']:.2f}",
        "FE_STATUS": fe_status, "FE_PASS": fe_totals["pass"], "FE_FAIL": fe_totals["fail"],
        "FE_SKIP": fe_totals["skip"], "FE_DURATION": f"{fe_totals['duration']:.2f}",
        "DB_EXIT": exit_codes.get("db", "n/a"),
        "BE_EXIT": exit_codes.get("be", "n/a"),
        "FE_EXIT": exit_codes.get("fe", "n/a"),
        "GLOBAL_VERDICT": verdict,
        # DB casos
        "TC_DB_01": db_results.get("test_insert", "n/a"),
        "TC_DB_02": db_results.get("test_select", "n/a"),
        "TC_DB_03": db_results.get("test_update", "n/a"),
        "TC_DB_04": db_results.get("test_delete", "n/a"),
        "TC_DB_05": db_results.get("test_constraints", "n/a"),
        "TC_DB_01_NOTES": "INSERT válido", "TC_DB_02_NOTES": "SELECT semillas",
        "TC_DB_03_NOTES": "UPDATE fila", "TC_DB_04_NOTES": "DELETE fila",
        "TC_DB_05_NOTES": "Constraint NOT NULL (psql debe fallar)",
        # BE failure snippet
        "BE_FAILURE_SNIPPET": be_totals.get("failure_snippet", ""),
        # FE failure snippet
        "FE_FAILURE_SNIPPET": fe_totals.get("failure_snippet", ""),
        # Comandos
        "COMMANDS_RUN": "bash lab1-unit-testing/run-all.sh",
        "RAW_JSON_SUMMARY": json.dumps({
            "db": {"results": db_results, "totals": db_totals, "exit": exit_codes.get("db")},
            "be": {"totals": be_totals, "cases": be_cases, "exit": exit_codes.get("be")},
            "fe": {"totals": fe_totals, "cases": fe_cases, "exit": exit_codes.get("fe")},
        }, ensure_ascii=False, indent=2),
    }

    # BE por id
    for tc_id, (cls, method) in BE_TC_MAP.items():
        c = find_be_case(be_cases, cls, method)
        ctx[tc_id.replace("-", "_")] = c["status"] if c else "n/a"
        ctx[tc_id.replace("-", "_") + "_MS"] = (c["time_ms"] if c else "n/a")
    # FE por id
    for tc_id, needle in FE_TC_MAP.items():
        c = find_fe_case(fe_cases, needle)
        ctx[tc_id.replace("-", "_")] = c["status"] if c else "n/a"
        ctx[tc_id.replace("-", "_") + "_MS"] = (c["time_ms"] if c else "n/a")

    out_md = render(template, ctx)
    out_path = reports_dir / "test-report.md"
    out_path.write_text(out_md)
    print(f"[ok] Reporte escrito en {out_path}")


if __name__ == "__main__":
    main()
