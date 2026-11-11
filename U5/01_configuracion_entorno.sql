-- ============================================================================
-- TALLER PRÁCTICO: VACUUM Y ANALYZE EN POSTGRESQL
-- Parte 2: Configuración del Entorno
-- ============================================================================

\c postgres
DROP DATABASE IF EXISTS taller_vacuum WITH (FORCE);
CREATE DATABASE taller_vacuum;
\c taller_vacuum

-- 2.2 Crear Tablas de Ejemplo
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    departamento VARCHAR(50),
    salario DECIMAL(10,2),
    fecha_contratacion DATE,
    activo BOOLEAN DEFAULT true
);

CREATE TABLE log_transacciones (
    id SERIAL PRIMARY KEY,
    empleado_id INTEGER,
    accion VARCHAR(50),
    fecha TIMESTAMP DEFAULT NOW(),
    datos TEXT
);

-- Desactivar autovacuum temporalmente en las tablas de práctica para observar las tuplas muertas antes del VACUUM manual
ALTER TABLE empleados SET (autovacuum_enabled = false);
ALTER TABLE log_transacciones SET (autovacuum_enabled = false);

-- 2.3 Insertar Datos Iniciales
SELECT setseed(0.5);

INSERT INTO empleados (nombre, departamento, salario, fecha_contratacion)
SELECT
    'Empleado ' || g,
    CASE (random() * 4)::int
        WHEN 0 THEN 'Ventas'
        WHEN 1 THEN 'TI'
        WHEN 2 THEN 'RH'
        WHEN 3 THEN 'Finanzas'
        ELSE 'Operaciones'
    END,
    round(((random() * 10000) + 30000)::numeric, 2),
    CURRENT_DATE - (random() * 3650)::int
FROM generate_series(1,1000) AS g;

INSERT INTO log_transacciones (empleado_id, accion, fecha, datos)
SELECT
    (random() * 999)::int + 1,
    CASE (random() * 3)::int
        WHEN 0 THEN 'INSERT'
        WHEN 1 THEN 'UPDATE'
        WHEN 2 THEN 'DELETE'
        ELSE 'SELECT'
    END,
    NOW() - ((random() * 5)::int || ' days')::interval,
    'Datos de prueba ' || g
FROM generate_series(1,5000) AS g;

SELECT pg_stat_force_next_flush();
