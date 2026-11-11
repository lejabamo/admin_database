-- ============================================================================
-- TALLER PRÁCTICO: COLLATION Y TABLESPACE EN POSTGRESQL (WINDOWS)
-- Sección 5: Ejercicio integral - empresa_multinacional
-- ============================================================================

\c postgres

-- Paso B: Crear la base de datos y los tablespaces
DROP DATABASE IF EXISTS empresa_multinacional;
CREATE DATABASE empresa_multinacional
    ENCODING 'UTF8'
    LC_COLLATE 'English_United States.1252'
    LC_CTYPE 'English_United States.1252'
    TEMPLATE template0;

\c empresa_multinacional

CREATE TABLESPACE ts_hr LOCATION 'C:/pgdata/hr';
CREATE TABLESPACE ts_finance LOCATION 'C:/pgdata/finance';
CREATE TABLESPACE ts_sales LOCATION 'C:/pgdata/sales';

SELECT spcname, pg_tablespace_location(oid) AS location
FROM pg_tablespace
WHERE spcname IN ('ts_hr', 'ts_finance', 'ts_sales');

-- Paso C: Recrear los collations ICU en la nueva base
CREATE COLLATION IF NOT EXISTS ignore_case (
    provider = icu, locale = 'und-u-ks-level2', deterministic = false
);
CREATE COLLATION IF NOT EXISTS ignore_accents (
    provider = icu, locale = 'und-u-ks-level1-kc-true', deterministic = false
);

-- Paso D: Crear tablas departamentales e insertar datos
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre TEXT COLLATE "ignore_case",
    apellido TEXT COLLATE "ignore_accents",
    departamento VARCHAR(50)
) TABLESPACE ts_hr;

CREATE TABLE movimientos_finanzas (
    id SERIAL PRIMARY KEY,
    concepto TEXT COLLATE "ignore_case",
    monto DECIMAL(12,2),
    fecha DATE
) TABLESPACE ts_finance;

CREATE TABLE pedidos_ventas (
    id SERIAL PRIMARY KEY,
    cliente TEXT COLLATE "ignore_accents",
    total DECIMAL(12,2),
    fecha DATE
) TABLESPACE ts_sales;

INSERT INTO empleados (nombre, apellido, departamento) VALUES
('María', 'González', 'HR'),
('Andrés', 'Pérez', 'HR'),
('john', 'Smith', 'HR'),
('maria', 'Gonzalez', 'HR');

-- Paso E: Consultar con ORDER BY, ILIKE y GROUP BY
SELECT * FROM empleados ORDER BY apellido;
SELECT * FROM empleados WHERE nombre ILIKE 'maria';
SELECT * FROM empleados WHERE nombre = 'maría';
SELECT * FROM empleados WHERE nombre = 'maria';
SELECT * FROM empleados WHERE nombre COLLATE "default" ILIKE 'mar_a';
SELECT apellido, COUNT(*) FROM empleados GROUP BY apellido ORDER BY COUNT(*) DESC;

-- Paso F: Verificar distribución de tablas por tablespace
SELECT tablename, tablespace FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablespace, tablename;
