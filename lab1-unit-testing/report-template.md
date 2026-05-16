# Reporte de ejecución — Lab 1 (Unit Testing) · CineVision

> Este archivo lo genera `generate-report.py` automáticamente al final de `run-all.sh`.
> No editar a mano. Mantener los encabezados y placeholders exactamente como están.

## Metadatos

- Fecha de ejecución (UTC): `<<TIMESTAMP_UTC>>`
- Rama Git: `<<GIT_BRANCH>>`
- Commit corto: `<<GIT_SHORT_SHA>>`
- Host: `<<HOSTNAME>>`
- Docker: `<<DOCKER_VERSION>>`
- Compose: `<<COMPOSE_VERSION>>`

## Flujo funcional cubierto

**Listado y detalle de películas** en CineVision. El flujo atraviesa tres capas:
1. **Frontend** — `MainPage.jsx`, `DetailPage.jsx`, `services/movieService.js`.
2. **Backend** — `MovieController`, `MovieServiceImpl`, `MovieDao`.
3. **Base de datos** — tabla `movie` en PostgreSQL.

## Resumen global

| Capa | Estado | Pasaron | Fallaron | Omitidos | Duración (s) |
|------|--------|---------|----------|----------|--------------|
| DB   | `<<DB_STATUS>>`   | `<<DB_PASS>>`   | `<<DB_FAIL>>`   | `<<DB_SKIP>>`   | `<<DB_DURATION>>`   |
| BE   | `<<BE_STATUS>>`   | `<<BE_PASS>>`   | `<<BE_FAIL>>`   | `<<BE_SKIP>>`   | `<<BE_DURATION>>`   |
| FE   | `<<FE_STATUS>>`   | `<<FE_PASS>>`   | `<<FE_FAIL>>`   | `<<FE_SKIP>>`   | `<<FE_DURATION>>`   |

- Exit code DB: `<<DB_EXIT>>`
- Exit code BE: `<<BE_EXIT>>`
- Exit code FE: `<<FE_EXIT>>`
- Veredicto global: `<<GLOBAL_VERDICT>>`   <!-- LISTO PARA PRESENTACIÓN | REVISAR FALLAS -->

## Tier 1 — Base de datos (PostgreSQL)

**Herramienta:** `psql` 15 dentro de contenedor cliente.
**Aislamiento aplicado:** esquema desechable `cine_vision_test` cargado por `init-test-schema.sql`. La producción no se toca.

| ID         | Caso                                  | Resultado          | Notas |
|------------|---------------------------------------|--------------------|-------|
| TC-DB-01   | INSERT de película válida             | `<<TC_DB_01>>`     | `<<TC_DB_01_NOTES>>` |
| TC-DB-02   | SELECT de filas sembradas             | `<<TC_DB_02>>`     | `<<TC_DB_02_NOTES>>` |
| TC-DB-03   | UPDATE de `is_display` y descripción  | `<<TC_DB_03>>`     | `<<TC_DB_03_NOTES>>` |
| TC-DB-04   | DELETE de la fila insertada           | `<<TC_DB_04>>`     | `<<TC_DB_04_NOTES>>` |
| TC-DB-05   | NOT NULL sobre `movie_name` (debe fallar el INSERT) | `<<TC_DB_05>>` | `<<TC_DB_05_NOTES>>` |

## Tier 2 — Backend (Spring Boot · JUnit 5 + Mockito)

**Herramientas:** JUnit Jupiter, Mockito, Spring Boot Test, MockMvc.
**Aislamiento aplicado:** `MovieDao` mockeado con `@Mock`; controladores probados con `@WebMvcTest` y `@MockBean` de `MovieService`. No se levanta contexto completo ni hay conexión real a PostgreSQL.

| ID         | Clase                       | Método                                          | Resultado          | Duración (ms)        |
|------------|-----------------------------|-------------------------------------------------|--------------------|----------------------|
| TC-BE-01   | MovieServiceImplTest        | getAllDisplayingMoviesInVision_returnsDaoResult | `<<TC_BE_01>>`     | `<<TC_BE_01_MS>>`    |
| TC-BE-02   | MovieServiceImplTest        | getAllComingSoonMovies_returnsDaoResult         | `<<TC_BE_02>>`     | `<<TC_BE_02_MS>>`    |
| TC-BE-03   | MovieServiceImplTest        | getMovieByMovieId_returnsDto                    | `<<TC_BE_03>>`     | `<<TC_BE_03_MS>>`    |
| TC-BE-04   | MovieServiceImplTest        | getMovieByMovieId_returnsNullWhenDaoReturnsNull | `<<TC_BE_04>>`     | `<<TC_BE_04_MS>>`    |
| TC-BE-05   | MovieControllerTest         | getDisplayingMovies                             | `<<TC_BE_05>>`     | `<<TC_BE_05_MS>>`    |
| TC-BE-06   | MovieControllerTest         | getComingSoonMovies                             | `<<TC_BE_06>>`     | `<<TC_BE_06_MS>>`    |
| TC-BE-07   | MovieControllerTest         | getMovieById                                    | `<<TC_BE_07>>`     | `<<TC_BE_07_MS>>`    |

Si hubo fallas, fragmento (≤ 20 líneas):

```
<<BE_FAILURE_SNIPPET>>
```

## Tier 3 — Frontend (React · Jest + React Testing Library)

**Herramientas:** Jest 27 (vía `react-scripts test`), React Testing Library, `jest.mock` para `axios` y servicios.
**Aislamiento aplicado:** `axios` mockeado; servicios (`MovieService`, `ActorService`, etc.) mockeados a nivel de clase; `react-redux` reemplazado por mock manual. Ningún render llama al backend.

| ID         | Archivo                                       | Caso                                                                   | Resultado          | Duración (ms)        |
|------------|-----------------------------------------------|------------------------------------------------------------------------|--------------------|----------------------|
| TC-FE-01   | `__tests__/services/movieService.test.js`     | getAllDisplayingMovies hace GET al endpoint correcto                   | `<<TC_FE_01>>`     | `<<TC_FE_01_MS>>`    |
| TC-FE-02   | `__tests__/services/movieService.test.js`     | getMovieById concatena el id en la URL                                 | `<<TC_FE_02>>`     | `<<TC_FE_02_MS>>`    |
| TC-FE-03   | `__tests__/services/movieService.test.js`     | getAllComingSoonMovies usa el endpoint comingSoonMovies                | `<<TC_FE_03>>`     | `<<TC_FE_03_MS>>`    |
| TC-FE-04   | `__tests__/pages/MainPage.test.jsx`           | MainPage renderiza nombres de películas tras useEffect                 | `<<TC_FE_04>>`     | `<<TC_FE_04_MS>>`    |
| TC-FE-05   | `__tests__/pages/DetailPage.test.jsx`         | DetailPage renderiza nombre, director y sinopsis                       | `<<TC_FE_05>>`     | `<<TC_FE_05_MS>>`    |

Si hubo fallas, fragmento (≤ 20 líneas):

```
<<FE_FAILURE_SNIPPET>>
```

## Mapa de test doubles (para el reporte de 1 página)

Esta sección lista, cruda, los tres elementos que el informe de una página debe justificar.

- **Unidad FE — `MovieService.getMovieById`**
  - Doble aplicado: **mock de `axios`** vía `jest.mock('axios')`.
  - Hecho objetivo: `axios.get` se reemplaza por `jest.fn` y se le inyecta el `data` esperado.
  - Principio del lab: "API-consumption functions must be mocked" / "Frontend unit tests must not contact sq-be".

- **Unidad BE — `MovieServiceImpl.getMovieByMovieId`**
  - Doble aplicado: **mock de `MovieDao`** vía `@Mock` de Mockito + `@InjectMocks` en el servicio.
  - Hecho objetivo: nunca se abre `JdbcConnection`; el comportamiento de `movieDao.getMovieById(id)` se programa con `when(...).thenReturn(...)`.
  - Principio del lab: "Repository/database-access functions (mock DB)" / "Ensuring isolation from the db and frontend".

- **Unidad DB — restricción NOT NULL sobre `movie_name`**
  - Doble aplicado: **fake schema** desechable `cine_vision_test` (no la base de producción).
  - Hecho objetivo: se carga un esquema FK-free desde `init-test-schema.sql` y se ejercita la constraint; el script de runner invierte el código de salida para validar el fallo esperado.
  - Principio del lab: "DB unit tests should not depend on application code; they validate SQL, constraints…".

## Comandos exactos ejecutados

```bash
<<COMMANDS_RUN>>
```

## Datos crudos para análisis posterior

```json
<<RAW_JSON_SUMMARY>>
```

> Fin del reporte generado automáticamente.
