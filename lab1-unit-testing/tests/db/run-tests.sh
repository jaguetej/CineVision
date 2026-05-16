#!/usr/bin/env bash
# Ejecuta los scripts SQL de la capa DB y reporta PASS/FAIL por archivo.
# Pensado para presentación en vivo: banners, colores ANSI, opcional DEMO_PACE.

set -u

# --- Colores ANSI (se desactivan si no hay TTY) ---
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'; BLUE=$'\033[34m'
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; RED=""; YELLOW=""; CYAN=""; BLUE=""
fi

PACE="${DEMO_PACE:-0}"     # segundos de pausa entre tests (0 = sin pausa, 0.5 = demo lenta)
TESTS_DIR="/tests"
LOG_DIR="/tests/.run-tests.tmp"
mkdir -p "$LOG_DIR" 2>/dev/null || true

banner () {
  local text="$1"
  local line; line=$(printf '═%.0s' {1..62})
  echo ""
  echo "${BOLD}${CYAN}${line}${RESET}"
  echo "${BOLD}${CYAN}║${RESET}  ${BOLD}${text}${RESET}"
  echo "${BOLD}${CYAN}${line}${RESET}"
}

pass=0
fail=0
total=0

run_one () {
  local file="$1"
  local invert="${2:-0}"
  local name
  name="$(basename "$file" .sql)"
  total=$((total+1))

  echo ""
  echo "${BOLD}${BLUE}▶ [${total}] Ejecutando ${name}.sql${RESET}"
  echo "${DIM}--- Contenido del test ---${RESET}"
  sed -n '1,30p' "$file" | sed "s/^/${DIM}│${RESET} /"
  echo "${DIM}--- Salida psql ---${RESET}"

  psql -v ON_ERROR_STOP=1 -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -f "$file" \
    2>&1 | tee "$LOG_DIR/${name}.out" | sed "s/^/  /"
  local rc=${PIPESTATUS[0]}

  if [ "$invert" = "1" ]; then
    if [ "$rc" -ne 0 ]; then
      echo "${BOLD}${GREEN}>>> RESULT: ${name} PASS${RESET}  ${DIM}(fallo esperado, psql exit=${rc})${RESET}"
      pass=$((pass+1))
    else
      echo "${BOLD}${RED}>>> RESULT: ${name} FAIL${RESET}  ${YELLOW}(no falló como se esperaba)${RESET}"
      fail=$((fail+1))
    fi
  else
    if [ "$rc" -eq 0 ]; then
      echo "${BOLD}${GREEN}>>> RESULT: ${name} PASS${RESET}"
      pass=$((pass+1))
    else
      echo "${BOLD}${RED}>>> RESULT: ${name} FAIL${RESET}  ${YELLOW}(psql exit=${rc})${RESET}"
      fail=$((fail+1))
    fi
  fi

  if [ "$PACE" != "0" ]; then
    sleep "$PACE"
  fi
}

banner "TIER 1 · BASE DE DATOS (PostgreSQL · psql)"
echo "${DIM}Conectado a: ${PGHOST}/${PGDATABASE} como ${PGUSER}${RESET}"

run_one "$TESTS_DIR/test_insert.sql"      0
run_one "$TESTS_DIR/test_select.sql"      0
run_one "$TESTS_DIR/test_update.sql"      0
run_one "$TESTS_DIR/test_delete.sql"      0
run_one "$TESTS_DIR/test_constraints.sql" 1

echo ""
echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [ "$fail" -eq 0 ]; then
  echo "${BOLD}${GREEN}>>> SUMMARY DB:  total=${total}  pass=${pass}  fail=${fail}  ✓${RESET}"
else
  echo "${BOLD}${RED}>>> SUMMARY DB:  total=${total}  pass=${pass}  fail=${fail}  ✗${RESET}"
fi
echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"

[ "$fail" -eq 0 ] && exit 0 || exit 1
