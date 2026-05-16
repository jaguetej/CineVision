# Lab 1 — Unit Testing (CineVision)

Pruebas unitarias automatizadas sobre el flujo "Listado y detalle de películas" de CineVision, distribuidas en tres capas (base de datos, backend y frontend) y orquestadas con Docker Compose.

## Requisitos

- Docker Desktop corriendo.
- Python 3.8 o superior (para el script que arma el reporte).
- Acceso a internet la primera vez (Docker descarga las imágenes base).

## Un solo comando

Desde la raíz del repo:

```bash
bash lab1-unit-testing/run-all.sh
```

Eso hace todo de principio a fin:

1. Verifica que Docker y Python estén disponibles.
2. Copia los tests desde `lab1-unit-testing/tests/` a sus rutas finales dentro del proyecto.
3. Construye las imágenes de test (Postgres, Maven y Node).
4. Ejecuta los tres tiers de forma secuencial (DB → BE → FE) con la salida visible en la terminal.
5. Genera `.reports/test-report.md` parseando los JUnit XML y los logs.
6. Levanta un visor web en `http://localhost:8088` que sirve el reporte y los logs.
7. Imprime un resumen final con los exit codes por capa y la URL del visor.

## Variantes

```bash
# Modo CI: sin pausas, sin visor
SKIP_VIEWER=1 bash lab1-unit-testing/run-all.sh

# Presentación lenta: pausa de 0.6 s entre tests SQL, ENTER entre tiers
DEMO_PACE=0.6 DEMO_INTERACTIVE=1 bash lab1-unit-testing/run-all.sh

# Re-ejecutar sin volver a copiar los tests a sus rutas finales
SKIP_SCAFFOLD=1 bash lab1-unit-testing/run-all.sh

# Cambiar el puerto del visor si 8088 está ocupado
VIEWER_PORT=8089 bash lab1-unit-testing/run-all.sh
```

## Detener el visor

```bash
docker compose -f docker-compose.tests.yml down -v
```

## Volver al estado inicial

```bash
bash lab1-unit-testing/clean.sh
```

Borra contenedores, volúmenes de cache, los tests copiados a sus rutas finales, `.reports/` y el `docker-compose.tests.yml` del repo raíz. No toca el código de producción ni los archivos fuente bajo `lab1-unit-testing/tests/`.

## Estructura

```
lab1-unit-testing/
├── README.md
├── run-all.sh                          # un solo comando que hace TODO
├── clean.sh                            # revierte el estado del repo
├── docker-compose.tests.yml            # orquestador de los 3 tiers + visor
├── generate-report.py                  # arma .reports/test-report.md
├── report-template.md                  # plantilla del reporte
├── nginx.conf                          # config del visor
├── viewer-index.html                   # página del visor
└── tests/
    ├── db/
    │   ├── init-test-schema.sql        # esquema desechable cine_vision_test
    │   ├── test_insert.sql
    │   ├── test_select.sql
    │   ├── test_update.sql
    │   ├── test_delete.sql
    │   ├── test_constraints.sql
    │   └── run-tests.sh                # ejecutor con PASS/FAIL por archivo
    ├── backend/
    │   ├── MovieServiceImplTest.java   # JUnit 5 + Mockito
    │   ├── MovieControllerTest.java    # @WebMvcTest + MockMvc
    │   └── surefire-snippet.xml        # configuración Surefire opcional
    └── frontend/
        ├── movieService.test.js        # Jest + axios mockeado
        ├── MainPage.test.jsx           # Jest + RTL + MovieService mockeado
        └── DetailPage.test.jsx         # Jest + RTL + servicios mockeados
```

## Qué se ve en pantalla

Durante la corrida, la terminal muestra:

- En el tier DB, cada script SQL con su contenido y la salida real de `psql`, más una línea `>>> RESULT: <nombre> PASS/FAIL` por archivo y un resumen final.
- En el tier BE, Maven Surefire imprime cada `@Test` con su nombre y duración, agrupados por clase de test.
- En el tier FE, Jest en modo `--verbose` lista cada caso con un check verde junto a la descripción literal del test.

Cuando termina, el visor en `http://localhost:8088` muestra el `test-report.md` renderizado con tablas por capa, badges PASS/FAIL coloreados, veredicto global, y enlaces directos a los logs crudos y JUnit XML.

## Reglas de aislamiento

- Los tests de backend no abren conexión real contra PostgreSQL: `MovieDao` se sustituye por un mock de Mockito.
- Los tests de frontend no llaman al backend real: `axios` y las clases de servicio se sustituyen con `jest.mock`.
- Los tests de DB no dependen de código de la aplicación: son scripts SQL puros ejecutados con `psql` contra un esquema `cine_vision_test` desechable que se carga de cero en cada corrida.

Cada tier corre en su propio contenedor, así que un fallo en una capa no enmascara ni propaga a las otras.
