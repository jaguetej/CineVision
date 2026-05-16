-- TC-DB-04 — DELETE
-- Borra la fila insertada por TC-DB-01 y verifica que no exista.

DELETE FROM movie WHERE movie_name = 'TC01 Inserted';

SELECT COUNT(*) AS remaining FROM movie WHERE movie_name = 'TC01 Inserted';
-- Debe devolver 0
