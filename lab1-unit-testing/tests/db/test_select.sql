-- TC-DB-02 — SELECT
-- Verifica que los datos sembrados en init-test-schema.sql sean recuperables.

SELECT movie_id, movie_name, is_display
FROM movie
WHERE movie_name LIKE 'Seed Movie%'
ORDER BY movie_id;
-- Debe devolver al menos 2 filas
