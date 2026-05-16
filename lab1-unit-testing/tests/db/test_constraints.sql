-- TC-DB-05 — CONSTRAINTS (NOT NULL)
-- Intenta insertar una película SIN nombre. Debe fallar.
-- run-tests.sh invierte el resultado para este archivo:
-- si psql sale != 0, se considera PASS.

INSERT INTO movie (movie_name, description, duration, release_date, is_display)
VALUES (NULL, 'sin nombre', 10, CURRENT_DATE, FALSE);
