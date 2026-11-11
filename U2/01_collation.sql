-- ============================================================================
-- TALLER PRÁCTICO: COLLATION Y TABLESPACE EN POSTGRESQL (WINDOWS)
-- Parte 1: Collation
-- ============================================================================

-- 3.2 Paso 1: Ver collations disponibles
SELECT collname, collencoding, collcollate, collctype
FROM pg_collation
WHERE collencoding = -1 OR collencoding = 6
ORDER BY collname
LIMIT 15;

SELECT collname, collprovider, collencoding, collcollate, collctype
FROM pg_collation
WHERE collname != 'C' AND collencoding IN (-1, 6)
ORDER BY collprovider, collname
LIMIT 10;

-- 3.3 Paso 2: Verificar el collation de la base de datos actual
SELECT
    current_database() AS database,
    datcollate AS database_collation,
    datctype  AS database_ctype
FROM pg_database
WHERE datname = current_database();

-- 3.4.1 Ver los locales de Windows disponibles para PostgreSQL (provider libc)
SELECT DISTINCT collcollate
FROM pg_collation
WHERE collcollate LIKE '%1252%';

-- 3.4 Paso 3: Crear una base de datos con collation específico (Opción A)
DROP DATABASE IF EXISTS pedidos_es;
CREATE DATABASE pedidos_es
    TEMPLATE template0
    ENCODING 'UTF8'
    LC_COLLATE 'English_United States.1252'
    LC_CTYPE 'English_United States.1252';

SELECT datname, datcollate, datctype
FROM pg_database
WHERE datname = 'pedidos_es';

\c pedidos_es

-- 3.5 Paso 4: Crear collations personalizados con ICU
CREATE COLLATION IF NOT EXISTS ignore_case (
    provider = icu,
    locale = 'und-u-ks-level2',
    deterministic = false
);

CREATE COLLATION IF NOT EXISTS ignore_accents (
    provider = icu,
    locale = 'und-u-ks-level1-kc-true',
    deterministic = false
);

-- 3.6 Paso 5: Tabla de práctica y ordenamiento
DROP TABLE IF EXISTS comparacion_collations;
CREATE TABLE comparacion_collations (
    id SERIAL PRIMARY KEY,
    texto_c TEXT COLLATE "C",
    texto_ignore_case TEXT COLLATE ignore_case,
    texto_ignore_accents TEXT COLLATE ignore_accents
);

INSERT INTO comparacion_collations VALUES
(1, 'casa', 'casa', 'casa'),
(2, 'Casa', 'Casa', 'Casa'),
(3, 'cáscara', 'cáscara', 'cáscara'),
(4, 'cascara', 'cascara', 'cascara');

SELECT texto_c FROM comparacion_collations ORDER BY texto_c;
SELECT texto_ignore_case FROM comparacion_collations ORDER BY texto_ignore_case;
SELECT texto_ignore_accents FROM comparacion_collations ORDER BY texto_ignore_accents;

-- 3.7 Paso 6: Comparaciones directas
SELECT
    'Ete' COLLATE ignore_case = 'ete' COLLATE ignore_case AS mayus_ignorada,
    'Ete' COLLATE ignore_case = 'Eté' COLLATE ignore_case AS acento_respetado;

SELECT
    'Ete' COLLATE ignore_accents = 'Eté' COLLATE ignore_accents AS acento_ignorado,
    'Ete' COLLATE ignore_accents = 'ete' COLLATE ignore_accents AS mayus_respetada;

SELECT a.texto_ignore_accents = b.texto_ignore_accents AS ignora_acento
FROM comparacion_collations a, comparacion_collations b
WHERE a.id = 3 AND b.id = 4;

-- 3.8 Paso 7: Caso práctico usuarios_empresa
DROP TABLE IF EXISTS usuarios_empresa;
CREATE TABLE usuarios_empresa (
    id SERIAL PRIMARY KEY,
    username TEXT COLLATE "C",
    email TEXT COLLATE ignore_case,
    nombre TEXT COLLATE ignore_accents,
    departamento TEXT
);

INSERT INTO usuarios_empresa (username, email, nombre, departamento) VALUES
('maria.gonzalez', 'Maria.Gonzalez@empresa.com', 'María González', 'Ventas'),
('andres.perez', 'Andres.Perez@empresa.com', 'Andrés Pérez', 'IT'),
('maria.gonzalez.s', 'maria.s@empresa.com', 'Maria Gonzalez', 'Ventas');

-- 3.9 Paso 8: Búsquedas y agrupamientos
SELECT * FROM usuarios_empresa
WHERE email = 'maria.gonzalez@empresa.com';

SELECT nombre, COUNT(*)
FROM usuarios_empresa
GROUP BY nombre
ORDER BY COUNT(*) DESC;
