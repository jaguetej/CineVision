-- TC-DB-03 — UPDATE
-- Cambia el flag is_display de la película semilla 2 y verifica la actualización.

UPDATE movie
SET is_display = TRUE,
    description = 'Actualizado por TC03'
WHERE movie_name = 'Seed Movie 2';

SELECT is_display, description
FROM movie
WHERE movie_name = 'Seed Movie 2';
-- is_display = t, description = 'Actualizado por TC03'
