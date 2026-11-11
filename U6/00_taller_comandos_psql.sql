-- Taller de comandos básicos de postgresql con psql (u6)
-- Secciones 1 a 4 y Ejercicio 1 / Ejercicio 2 (Creación de taller_test y usuarios)

-- Ejercicio 1: Conexión y Exploración
\l
\c postgres
SELECT current_database();
\conninfo

-- Ejercicio 2: Creación de base de datos taller_test y tabla usuarios
DROP DATABASE IF EXISTS taller_test WITH (FORCE);
CREATE DATABASE taller_test;
\c taller_test

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO usuarios (nombre, email) VALUES
('Carlos Ramírez', 'carlos.ramirez@correo.com'),
('María Fernanda Gómez', 'maria.gomez@correo.com'),
('Andrés Felipe Soto', 'andres.soto@correo.com'),
('Laura Valentina Ruiz', 'laura.ruiz@correo.com');

-- Exploración de la tabla creada (Sección 3 y 4)
\dt
\dt+
\z usuarios
\d usuarios
\di

SELECT * FROM usuarios LIMIT 10;
EXPLAIN SELECT * FROM usuarios;

