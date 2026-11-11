-- Taller práctico: vacuum y analyze en postgresql
-- Parte 3: Ejercicios Prácticos (Monitoreo, Bloat, VACUUM, VACUUM FULL y ANALYZE)

\c taller_vacuum

-- 3.1 Monitoreo del Estado Actual
-- Ejercicio 1: Verificar estadísticas de tamaño de tablas
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS tamano_total,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS tamano_tabla,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) -
        pg_relation_size(schemaname||'.'||tablename)) AS tamano_indices
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Ejercicio 2: Verificar estadísticas de VACUUM
SELECT
    schemaname,
    relname AS tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    vacuum_count,
    autovacuum_count
FROM pg_stat_all_tables
WHERE schemaname = 'public';

-- 3.2 Simular Bloat y Tuplas Muertas
-- Ejercicio 3: Crear tuplas muertas (con bloque ROLLBACK y actualizaciones efectivas)
BEGIN;
UPDATE empleados
SET salario = salario * 1.1
WHERE departamento = 'Ventas';

DELETE FROM log_transacciones
WHERE fecha < CURRENT_DATE - INTERVAL '1 day';
ROLLBACK;

-- Ejecutamos también UPDATE y DELETE confirmados para reflejar el conteo en pg_stat_all_tables
UPDATE empleados
SET salario = salario * 1.05
WHERE departamento IN ('Ventas', 'TI');

DELETE FROM log_transacciones
WHERE fecha < CURRENT_DATE - INTERVAL '2 days';

SELECT pg_stat_force_next_flush();

-- Ejercicio 4: Verificar tuplas muertas
SELECT
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    round(n_dead_tup::numeric / (n_live_tup + n_dead_tup) * 100, 2) AS porcentaje_muertas
FROM pg_stat_all_tables
WHERE schemaname = 'public'
  AND (n_live_tup + n_dead_tup) > 0;

-- 3.3 Ejecutar VACUUM Manual
-- Ejercicio 5: VACUUM estándar
SELECT pg_size_pretty(pg_relation_size('empleados')) AS tamano_antes;
VACUUM VERBOSE empleados;
SELECT pg_size_pretty(pg_relation_size('empleados')) AS tamano_despues;

-- Ejercicio 6: VACUUM FULL (comparación sobre tabla con bloat)
CREATE TABLE empleados_copia AS SELECT * FROM empleados;
UPDATE empleados_copia SET salario = salario + 100;
UPDATE empleados_copia SET salario = salario + 100;

SELECT 'Original' AS tabla, pg_size_pretty(pg_relation_size('empleados')) AS tamano
UNION ALL
SELECT 'Copia (antes de VACUUM FULL)', pg_size_pretty(pg_relation_size('empleados_copia'));

VACUUM FULL VERBOSE empleados_copia;

SELECT 'Original' AS tabla, pg_size_pretty(pg_relation_size('empleados')) AS tamano
UNION ALL
SELECT 'Copia (después de VACUUM FULL)', pg_size_pretty(pg_relation_size('empleados_copia'));

-- 3.4 Ejecutar ANALYZE
-- Ejercicio 7: ANALYZE manual
SELECT
    schemaname,
    tablename,
    attname,
    null_frac,
    avg_width,
    n_distinct
FROM pg_stats
WHERE tablename = 'empleados'
LIMIT 10;

ANALYZE VERBOSE empleados;

SELECT
    schemaname,
    tablename,
    attname,
    null_frac,
    avg_width,
    n_distinct,
    left(most_common_vals::text, 45) AS most_common_vals_sample
FROM pg_stats
WHERE tablename = 'empleados'
LIMIT 10;

-- 3.5 Combinar VACUUM y ANALYZE
-- Ejercicio 8: VACUUM ANALYZE
VACUUM (VERBOSE, ANALYZE) empleados, log_transacciones;
SELECT pg_stat_force_next_flush();

SELECT
    schemaname,
    relname AS tablename,
    last_vacuum,
    last_analyze,
    n_live_tup,
    n_dead_tup
FROM pg_stat_all_tables
WHERE schemaname = 'public';
