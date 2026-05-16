-- Esquema mínimo y aislado para tests unitarios de la capa de base de datos.
-- NO refleja la tabla movie de producción tal cual: aplana FKs a category/director/image
-- para poder ejercitar CRUD + NOT NULL constraints sin depender del resto del modelo.
-- Esto cumple la regla del lab: los tests de DB no deben acoplarse al backend.

CREATE TABLE IF NOT EXISTS movie (
    movie_id            SERIAL PRIMARY KEY,
    movie_name          VARCHAR(255) NOT NULL,
    description         TEXT,
    duration            INT          NOT NULL DEFAULT 0,
    release_date        DATE,
    is_display          BOOLEAN      NOT NULL DEFAULT FALSE,
    movie_trailer_url   VARCHAR(512),
    category_name       VARCHAR(120),
    director_name       VARCHAR(120),
    image_url           VARCHAR(512)
);

-- Seed mínimo para ejercitar el SELECT inicial
INSERT INTO movie (movie_name, description, duration, release_date, is_display, category_name, director_name, image_url)
VALUES
  ('Seed Movie 1', 'Película semilla 1', 100, CURRENT_DATE - INTERVAL '5 days', TRUE,  'Drama',  'Director A', 'http://img/1.png'),
  ('Seed Movie 2', 'Película semilla 2',  90, CURRENT_DATE + INTERVAL '10 days', FALSE, 'Acción', 'Director B', 'http://img/2.png');
