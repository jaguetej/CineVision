-- TC-DB-01 — INSERT
-- Pre:  tabla movie con seed (2 filas)
-- Acción: insertar una película válida.
-- Post: SELECT debe encontrarla.

INSERT INTO movie (movie_name, description, duration, release_date, is_display, category_name, director_name, image_url)
VALUES ('TC01 Inserted', 'Insertado por test', 110, CURRENT_DATE, TRUE, 'Drama', 'Director X', 'http://img/tc01.png');

SELECT COUNT(*) AS inserted_count FROM movie WHERE movie_name = 'TC01 Inserted';
-- Debe devolver 1
