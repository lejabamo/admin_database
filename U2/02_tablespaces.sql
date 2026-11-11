-- ============================================================================
-- TALLER PRÁCTICO: COLLATION Y TABLESPACE EN POSTGRESQL (WINDOWS)
-- Parte 2: Tablespaces
-- ============================================================================

\c pedidos_es

-- 4.3 Paso 2: Crear los tablespaces en PostgreSQL
CREATE TABLESPACE ts_indices LOCATION 'C:/pgdata/indices';
CREATE TABLESPACE ts_archivos LOCATION 'C:/pgdata/archivos';

SELECT spcname, pg_tablespace_location(oid) AS location
FROM pg_tablespace
WHERE spcname LIKE 'ts_%';

-- 4.4 Paso 3: Usar tablespaces en tablas e índices
DROP TABLE IF EXISTS facturas;
CREATE TABLE facturas (
    id SERIAL PRIMARY KEY,
    numero_factura VARCHAR(20),
    cliente VARCHAR(100),
    monto DECIMAL(10,2),
    fecha DATE
) TABLESPACE ts_archivos;

CREATE INDEX idx_facturas_cliente
    ON facturas(cliente) TABLESPACE ts_indices;

SELECT tablename, tablespace FROM pg_tables WHERE tablename = 'facturas';
SELECT indexname, tablespace FROM pg_indexes WHERE tablename = 'facturas';

-- 4.5 Paso 4: Tablespaces por defecto
ALTER USER postgres SET default_tablespace = ts_archivos;
ALTER DATABASE postgres SET default_tablespace = ts_archivos;
SET default_tablespace = ts_archivos;
SHOW default_tablespace;

-- Validación: crear tabla sin cláusula TABLESPACE y confirmar ubicación
DROP TABLE IF EXISTS clientes_temp;
CREATE TABLE clientes_temp (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100)
);

SELECT tablename, tablespace FROM pg_tables WHERE tablename = 'clientes_temp';

-- Restaurar default_tablespace en sesión para pruebas explícitas posteriores
SET default_tablespace = '';

-- 4.6 Parámetros clave de un tablespace
ALTER TABLESPACE ts_indices SET (random_page_cost = 1.1);
SELECT spcname, spcoptions FROM pg_tablespace WHERE spcname = 'ts_indices';

-- 4.7 Gestión avanzada: mover objetos y particiones
ALTER TABLE clientes_temp SET TABLESPACE ts_archivos;
ALTER INDEX clientes_temp_pkey SET TABLESPACE ts_indices;

SELECT tablename, tablespace FROM pg_tables WHERE tablename = 'clientes_temp';
SELECT indexname, tablespace FROM pg_indexes WHERE tablename = 'clientes_temp';

-- Particiones en tablespaces distintos
DROP TABLE IF EXISTS ventas;
CREATE TABLE ventas (
    id SERIAL,
    fecha_venta DATE,
    monto DECIMAL(10,2)
) PARTITION BY RANGE (fecha_venta);

CREATE TABLE ventas_2023 PARTITION OF ventas
    FOR VALUES FROM ('2023-01-01')
    TO ('2024-01-01') TABLESPACE ts_archivos;

CREATE TABLE ventas_2024 PARTITION OF ventas
    FOR VALUES FROM ('2024-01-01')
    TO ('2025-01-01') TABLESPACE ts_indices;

INSERT INTO ventas (fecha_venta, monto) VALUES
('2023-03-15', 1500.00),
('2023-08-20', 2300.50),
('2024-02-10', 1800.00),
('2024-09-05', 3100.75);

SELECT * FROM ventas ORDER BY fecha_venta;
EXPLAIN SELECT * FROM ventas WHERE fecha_venta = '2023-06-01';
EXPLAIN SELECT * FROM ventas WHERE fecha_venta = '2024-06-01';

-- 4.8 Monitoreo y mantenimiento
SELECT spcname AS tablespace,
       pg_size_pretty(pg_tablespace_size(spcname)) AS size
FROM pg_tablespace;

SELECT schemaname, tablename, tablespace,
       pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS relation_size,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size
FROM pg_tables
WHERE tablespace IS NOT NULL
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
