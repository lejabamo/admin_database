-- Taller práctico: vacuum y analyze en postgresql
-- Partes 4 y 5: Configuración de Autovacuum, Vista de Monitoreo y Escenarios

\c taller_vacuum

-- 4.1 Configurar Parámetros de Autovacuum
-- Ejercicio 9: Ver configuración actual
SELECT name, setting, unit, context
FROM pg_settings
WHERE name LIKE '%autovacuum%'
   OR name LIKE '%vacuum%'
ORDER BY name;

-- Ejercicio 10: Modificar parámetros para una tabla específica
ALTER TABLE log_transacciones SET (
    autovacuum_enabled = true,
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_scale_factor = 0.05
);

SELECT
    relname,
    reloptions
FROM pg_class
WHERE relname = 'log_transacciones';

-- 4.2 Monitoreo Continuo
-- Ejercicio 11: Crear vista de monitoreo
CREATE OR REPLACE VIEW vacuum_monitor AS
SELECT
    schemaname,
    relname AS tablename,
    n_live_tup,
    n_dead_tup,
    round(n_dead_tup::numeric / GREATEST(n_live_tup + n_dead_tup, 1) * 100, 2) AS dead_percent,
    last_vacuum,
    last_autovacuum,
    vacuum_count,
    autovacuum_count,
    pg_size_pretty(pg_relation_size(schemaname||'.'||relname)) AS table_size
FROM pg_stat_all_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND n_live_tup > 0
ORDER BY n_dead_tup DESC;

-- Generamos algunas actualizaciones en log_transacciones para observar el monitor en acción
UPDATE log_transacciones SET accion = 'PROCESADO' WHERE id <= 450;
SELECT pg_stat_force_next_flush();

SELECT * FROM vacuum_monitor LIMIT 10;

-- 5.1 Escenarios Comunes
-- Caso 1: Tabla con alto volumen de UPDATES/DELETES
ALTER TABLE log_transacciones SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_vacuum_threshold = 1000
);

-- Caso 2: Tabla grande con pocos cambios
ALTER TABLE empleados SET (
    autovacuum_enabled = true,
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_vacuum_threshold = 10000
);

-- Script adicional de monitoreo de bloat con clasificación de estado
SELECT
    schemaname,
    relname AS tablename,
    n_live_tup,
    n_dead_tup,
    round(n_dead_tup::numeric / GREATEST(n_live_tup + n_dead_tup, 1) * 100, 2) AS dead_percent,
    CASE
        WHEN n_dead_tup > n_live_tup * 0.2 THEN 'ALERTA'
        WHEN n_dead_tup > n_live_tup * 0.1 THEN 'ADVERTENCIA'
        ELSE 'OK'
    END AS estado
FROM pg_stat_all_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND n_live_tup >= 100
ORDER BY n_dead_tup DESC;

