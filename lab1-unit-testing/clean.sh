#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Lab 1 · Unit Testing · CineVision — limpieza completa.
#
# Borra TODO lo que run-all.sh copió/generó, dejando el repo exactamente
# como estaba antes. NO toca el código de producción ni los archivos fuente
# bajo lab1-unit-testing/tests/.
#
# Uso:
#   bash lab1-unit-testing/clean.sh           # limpieza estándar (con confirmación)
#   bash lab1-unit-testing/clean.sh --yes     # sin confirmación (para CI)
#   bash lab1-unit-testing/clean.sh --deep    # limpia también target/ y node_modules/
# ─────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

# Colores
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'

ASK_CONFIRM=1
DEEP=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASK_CONFIRM=0 ;;
    --deep)   DEEP=1 ;;
  esac
done

echo ""
echo "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${CYAN}║  LIMPIEZA · Lab 1 Unit Testing · CineVision                        ║${RESET}"
echo "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Voy a borrar lo siguiente:"
echo "  ${DIM}·${RESET} contenedores: lab1-movie-db, lab1-movie-db-tests, lab1-movie-be-tests, lab1-movie-fe-tests, lab1-report-viewer"
echo "  ${DIM}·${RESET} volúmenes:    maven-cache, npm-cache (del compose de tests)"
echo "  ${DIM}·${RESET} archivos:     docker-compose.tests.yml, sq-tests/, .reports/"
echo "  ${DIM}·${RESET} tests BE:     movieService/src/test/java/com/kaankaplan/movieService/business/MovieServiceImplTest.java"
echo "  ${DIM}·${RESET}               movieService/src/test/java/com/kaankaplan/movieService/controller/MovieControllerTest.java"
echo "  ${DIM}·${RESET} tests FE:     frontend/src/__tests__/services/movieService.test.js"
echo "  ${DIM}·${RESET}               frontend/src/__tests__/pages/MainPage.test.jsx"
echo "  ${DIM}·${RESET}               frontend/src/__tests__/pages/DetailPage.test.jsx"
echo "  ${DIM}·${RESET} junit:        frontend/junit.xml, frontend/jest-output.json"
if [ "$DEEP" = "1" ]; then
  echo "  ${YELLOW}·${RESET} (deep)       movieService/target/, frontend/node_modules/"
fi
echo ""
echo "${BOLD}NO voy a tocar:${RESET}"
echo "  · El código de producción (controllers, services, dao, entities, pages, components)."
echo "  · Los archivos fuente bajo lab1-unit-testing/tests/."
echo "  · run-all.sh, clean.sh, README.md"
echo ""

if [ "$ASK_CONFIRM" = "1" ]; then
  read -r -p "${YELLOW}¿Continuar? [y/N] ${RESET}" answer
  case "$answer" in
    y|Y|yes|YES|s|S|si|SI|sí|SÍ) ;;
    *) echo "${RED}Cancelado.${RESET}"; exit 1 ;;
  esac
fi

step () { echo ""; echo "${BOLD}${CYAN}▶ $1${RESET}"; }

# ─────────── 1. Detener y borrar contenedores ───────────
step "1. Deteniendo contenedores"
if [ -f docker-compose.tests.yml ]; then
  docker compose -f docker-compose.tests.yml down -v --remove-orphans 2>/dev/null || true
fi
# Por si alguno quedó suelto
for c in lab1-movie-db lab1-movie-db-tests lab1-movie-be-tests lab1-movie-fe-tests lab1-report-viewer; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
    docker rm -f "$c" >/dev/null 2>&1 || true
    echo "  ${GREEN}✓${RESET} contenedor $c eliminado"
  fi
done

# ─────────── 2. Volúmenes ───────────
step "2. Borrando volúmenes nombrados (cachés de Maven y npm de los tests)"
for v in maven-cache npm-cache; do
  full_name=$(docker volume ls -q --filter "name=${v}$")
  if [ -n "$full_name" ]; then
    docker volume rm -f "$full_name" >/dev/null 2>&1 || true
    echo "  ${GREEN}✓${RESET} volumen $full_name borrado"
  fi
done
# Volúmenes con prefijo del proyecto (compose les antepone el nombre del repo)
docker volume ls --format '{{.Name}}' | grep -E '(_maven-cache|_npm-cache)$' | while read -r v; do
  docker volume rm -f "$v" >/dev/null 2>&1 || true
  echo "  ${GREEN}✓${RESET} volumen $v borrado"
done

# ─────────── 3. Archivos generados / copiados ───────────
step "3. Borrando archivos generados"

rm_path () {
  local p="$1"
  if [ -e "$p" ]; then
    rm -rf "$p"
    echo "  ${GREEN}✓${RESET} $p"
  fi
}

# DB
rm_path "sq-tests"

# .reports/
rm_path ".reports"

# docker-compose.tests.yml en la raíz
rm_path "docker-compose.tests.yml"

# Tests BE (solo los que creó el scaffolding — no toca AppTest.java original ni otros)
rm_path "movieService/src/test/java/com/kaankaplan/movieService/business/MovieServiceImplTest.java"
rm_path "movieService/src/test/java/com/kaankaplan/movieService/controller/MovieControllerTest.java"
# Limpia los directorios solo si quedaron vacíos
for d in \
  "movieService/src/test/java/com/kaankaplan/movieService/business" \
  "movieService/src/test/java/com/kaankaplan/movieService/controller"; do
  if [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
    rmdir "$d"
    echo "  ${GREEN}✓${RESET} $d (directorio vacío)"
  fi
done

# Tests FE
rm_path "frontend/src/__tests__/services/movieService.test.js"
rm_path "frontend/src/__tests__/pages/MainPage.test.jsx"
rm_path "frontend/src/__tests__/pages/DetailPage.test.jsx"
for d in "frontend/src/__tests__/services" "frontend/src/__tests__/pages" "frontend/src/__tests__"; do
  if [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
    rmdir "$d"
    echo "  ${GREEN}✓${RESET} $d (directorio vacío)"
  fi
done

# Artefactos jest en la raíz del frontend
rm_path "frontend/junit.xml"
rm_path "frontend/jest-output.json"

# ─────────── 4. Deep clean opcional ───────────
if [ "$DEEP" = "1" ]; then
  step "4. (deep) Borrando builds completos"
  rm_path "movieService/target"
  rm_path "frontend/node_modules"
fi

# ─────────── Resumen ───────────
echo ""
echo "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${GREEN}║  LIMPIEZA COMPLETA · Repo listo para volver a correr run-all.sh    ║${RESET}"
echo "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Siguiente paso:"
echo "  ${BOLD}bash lab1-unit-testing/run-all.sh${RESET}"
echo ""
