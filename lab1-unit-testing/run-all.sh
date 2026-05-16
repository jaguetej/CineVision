#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Lab 1 · Unit Testing · CineVision — orquestador de un solo comando.
#
# Hace TODO de principio a fin:
#   1) verifica prerequisitos
#   2) copia los tests desde lab1-unit-testing/tests/ a sus rutas finales
#   3) levanta los 3 contenedores de test (DB · BE · FE) con banners visuales
#   4) parsea los artefactos y genera .reports/test-report.md
#   5) arranca el visor HTTP en http://localhost:8088
#
# Variables de entorno (opcionales):
#   DEMO_PACE=0.6           pausa entre tests SQL para presentación en vivo
#   DEMO_INTERACTIVE=1      pausa con ENTER entre tiers
#   SKIP_SCAFFOLD=1         no copia archivos (asume que ya están en su sitio)
#   SKIP_VIEWER=1           no levanta el contenedor del visor
#   VIEWER_PORT=8088        cambia el puerto del visor si 8088 está ocupado
#
# Uso:
#   bash lab1-unit-testing/run-all.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e
set -o pipefail

# Ubicarnos en la raíz del repo (donde está pom.xml)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

# Colores ANSI
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'
CYAN=$'\033[36m'; BLUE=$'\033[34m'; MAGENTA=$'\033[35m'

big_banner () {
  local text="$1"
  local color="${2:-$CYAN}"
  echo ""
  echo "${BOLD}${color}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  printf "${BOLD}${color}║${RESET}  ${BOLD}%-64s${RESET}  ${BOLD}${color}║${RESET}\n" "$text"
  echo "${BOLD}${color}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
}

step () {
  echo ""
  echo "${BOLD}${BLUE}▶ $1${RESET}"
}

pause_if_demo () {
  if [ -t 0 ] && [ "${DEMO_INTERACTIVE:-0}" = "1" ]; then
    echo "${YELLOW}Presiona ENTER para continuar...${RESET}"
    read -r _
  fi
}

VIEWER_PORT="${VIEWER_PORT:-8088}"
LAB_DIR="$SCRIPT_DIR"

# ─────────────────────────────────────────────────────────────────────────────
big_banner "EXTENDED LABORATORY 1 · UNIT TESTING · CINEVISION" "$MAGENTA"
echo "${BOLD}Flujo:${RESET} Listado y detalle de películas (FE ↔ BE ↔ DB)"
echo "${BOLD}Modo:${RESET}  scaffolding + tests + viewer en un solo comando."
echo "${BOLD}Raíz del repo:${RESET} $REPO_ROOT"

# ─────────── PASO 0: prerequisitos ───────────
step "Paso 0 · Verificando prerequisitos"
for tool in docker python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "${RED}[!] Falta '$tool' en el PATH.${RESET}"
    exit 2
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "${RED}[!] Docker no está corriendo. Abre Docker Desktop y reintenta.${RESET}"
  exit 2
fi

for f in pom.xml frontend/package.json movieService/pom.xml; do
  if [ ! -f "$f" ]; then
    echo "${RED}[!] No encuentro $f en $REPO_ROOT. ¿Estás en el repo CineVision?${RESET}"
    exit 2
  fi
done
echo "${GREEN}✓ Docker OK, Python3 OK, estructura del repo OK.${RESET}"

mkdir -p .reports

# ─────────── PASO 1: scaffolding ───────────
if [ "${SKIP_SCAFFOLD:-0}" = "0" ]; then
  step "Paso 1 · Copiando archivos a sus rutas finales"

  # DB
  mkdir -p sq-tests/db
  cp -f "$LAB_DIR/tests/db/init-test-schema.sql" sq-tests/db/
  cp -f "$LAB_DIR/tests/db/test_insert.sql"      sq-tests/db/
  cp -f "$LAB_DIR/tests/db/test_select.sql"      sq-tests/db/
  cp -f "$LAB_DIR/tests/db/test_update.sql"      sq-tests/db/
  cp -f "$LAB_DIR/tests/db/test_delete.sql"      sq-tests/db/
  cp -f "$LAB_DIR/tests/db/test_constraints.sql" sq-tests/db/
  cp -f "$LAB_DIR/tests/db/run-tests.sh"         sq-tests/db/
  chmod +x sq-tests/db/run-tests.sh

  # nginx config (para el viewer)
  cp -f "$LAB_DIR/nginx.conf" sq-tests/nginx.conf

  # Index HTML del viewer (se sirve desde .reports/)
  cp -f "$LAB_DIR/viewer-index.html" .reports/index.html

  # BE
  BE_BUSINESS="movieService/src/test/java/com/kaankaplan/movieService/business"
  BE_CONTROLLER="movieService/src/test/java/com/kaankaplan/movieService/controller"
  mkdir -p "$BE_BUSINESS" "$BE_CONTROLLER"
  cp -f "$LAB_DIR/tests/backend/MovieServiceImplTest.java" "$BE_BUSINESS/"
  cp -f "$LAB_DIR/tests/backend/MovieControllerTest.java"  "$BE_CONTROLLER/"

  # FE
  FE_SERVICES="frontend/src/__tests__/services"
  FE_PAGES="frontend/src/__tests__/pages"
  mkdir -p "$FE_SERVICES" "$FE_PAGES"
  cp -f "$LAB_DIR/tests/frontend/movieService.test.js" "$FE_SERVICES/"
  cp -f "$LAB_DIR/tests/frontend/MainPage.test.jsx"    "$FE_PAGES/"
  cp -f "$LAB_DIR/tests/frontend/DetailPage.test.jsx"  "$FE_PAGES/"

  # docker-compose
  cp -f "$LAB_DIR/docker-compose.tests.yml" docker-compose.tests.yml

  echo "${GREEN}✓ Archivos copiados. Tests listos para ejecutarse.${RESET}"
else
  echo "${DIM}(saltando scaffolding por SKIP_SCAFFOLD=1)${RESET}"
fi

# ─────────── PASO 2: build images ───────────
step "Paso 2 · Construyendo imágenes de test"
docker compose -f docker-compose.tests.yml build

# Inicializamos los exit codes
DB_EXIT=99; BE_EXIT=99; FE_EXIT=99

# ─────────── TIER 1: DB ───────────
big_banner "TIER 1 · BASE DE DATOS (PostgreSQL · psql)" "$CYAN"
echo "Levantando postgres limpio para tests y ejecutando los 5 scripts SQL."
pause_if_demo
set +e
docker compose -f docker-compose.tests.yml up \
  --abort-on-container-exit --exit-code-from movie-db-tests \
  movie-db-tests-postgres movie-db-tests
DB_EXIT=$?
set -e
docker compose -f docker-compose.tests.yml stop movie-db-tests-postgres >/dev/null 2>&1 || true

# ─────────── TIER 2: BE ───────────
big_banner "TIER 2 · BACKEND (Spring Boot · JUnit 5 + Mockito)" "$CYAN"
echo "Ejecutando 'mvn test' sobre movieService con MovieDao mockeado (sin tocar PostgreSQL real)."
pause_if_demo
set +e
docker compose -f docker-compose.tests.yml up \
  --abort-on-container-exit --exit-code-from movie-be-tests \
  movie-be-tests
BE_EXIT=$?
set -e

# ─────────── TIER 3: FE ───────────
big_banner "TIER 3 · FRONTEND (React · Jest + RTL)" "$CYAN"
echo "Ejecutando Jest --verbose. axios y servicios mockeados con jest.mock (sin tocar el backend real)."
pause_if_demo
set +e
docker compose -f docker-compose.tests.yml up \
  --abort-on-container-exit --exit-code-from movie-fe-tests \
  movie-fe-tests
FE_EXIT=$?
set -e

# Persistimos códigos de salida
cat > .reports/exit-codes.json <<EOF
{
  "db": $DB_EXIT,
  "be": $BE_EXIT,
  "fe": $FE_EXIT
}
EOF

# ─────────── PASO 3: generar reporte ───────────
big_banner "PASO 3 · Generando .reports/test-report.md" "$BLUE"
python3 "$LAB_DIR/generate-report.py" "$REPO_ROOT"

# ─────────── PASO 4: viewer HTTP ───────────
if [ "${SKIP_VIEWER:-0}" = "0" ]; then
  big_banner "PASO 4 · Levantando visor web" "$BLUE"

  # Asegurar que index.html esté en .reports/ (por si SKIP_SCAFFOLD=1)
  if [ ! -f .reports/index.html ]; then
    cp -f "$LAB_DIR/viewer-index.html" .reports/index.html
  fi

  # Si el puerto está ocupado, advertimos
  if (echo > /dev/tcp/127.0.0.1/$VIEWER_PORT) 2>/dev/null; then
    echo "${YELLOW}⚠ El puerto $VIEWER_PORT ya está en uso. El visor podría no levantar.${RESET}"
    echo "${YELLOW}  Vuelve a correr con: VIEWER_PORT=8089 bash lab1-unit-testing/run-all.sh${RESET}"
  fi

  docker compose -f docker-compose.tests.yml up -d report-viewer

  # Detectar IP local (útil cuando se proyecta desde otra máquina)
  LAN_IP=$(ipconfig getifaddr en0 2>/dev/null \
           || ipconfig getifaddr en1 2>/dev/null \
           || hostname -I 2>/dev/null | awk '{print $1}' \
           || echo "127.0.0.1")
fi

# ─────────── Resumen final ───────────
big_banner "RESUMEN" "$MAGENTA"
echo "${BOLD}Exit codes:${RESET}"
echo "  DB: $DB_EXIT"
echo "  BE: $BE_EXIT"
echo "  FE: $FE_EXIT"
echo ""

if [ "$DB_EXIT" -eq 0 ] && [ "$BE_EXIT" -eq 0 ] && [ "$FE_EXIT" -eq 0 ]; then
  echo "${BOLD}${GREEN}✔ LISTO PARA PRESENTACIÓN${RESET}"
else
  echo "${BOLD}${RED}✗ REVISAR FALLAS${RESET}"
fi
echo ""
echo "${BOLD}Reporte estructurado:${RESET} .reports/test-report.md"
echo "${BOLD}Logs crudos:${RESET} .reports/db.log · .reports/be.log · .reports/fe.log"

if [ "${SKIP_VIEWER:-0}" = "0" ]; then
  echo ""
  echo "${BOLD}${GREEN}Visor web disponible en:${RESET}"
  echo "   ${BOLD}${CYAN}http://localhost:${VIEWER_PORT}${RESET}"
  echo "   ${DIM}(en la red local: http://${LAN_IP}:${VIEWER_PORT})${RESET}"
  echo ""
  echo "${DIM}Para detener el visor:  docker compose -f docker-compose.tests.yml down${RESET}"
fi

# Salimos con un código compuesto: 0 si todos pasan, 1 si alguno falla
if [ "$DB_EXIT" -eq 0 ] && [ "$BE_EXIT" -eq 0 ] && [ "$FE_EXIT" -eq 0 ]; then
  exit 0
else
  exit 1
fi
