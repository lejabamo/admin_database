-- ============================================================
-- 01_parametros_memoria.sql
-- Objetivo: revisar los parametros de memoria mas importantes
-- de una instancia PostgreSQL y su valor actual.
-- ============================================================

\echo '=== 1. Version del servidor ==='
SELECT version();

\echo ''
\echo '=== 2. Parametros de memoria compartida y de trabajo ==='
SELECT
    name,
    setting,
    unit,
    category,
    short_desc,
    context        -- indica si requiere reinicio (postmaster) o reload
FROM pg_settings
WHERE name IN (
    'shared_buffers',
    'huge_pages',
    'work_mem',
    'maintenance_work_mem',
    'autovacuum_work_mem',
    'effective_cache_size',
    'wal_buffers',
    'temp_buffers',
    'max_connections',
    'shared_memory_type',
    'dynamic_shared_memory_type'
)
ORDER BY name;

\echo ''
\echo '=== 3. Memoria estimada total reservada por shared_buffers + wal_buffers ==='
SELECT
    pg_size_pretty(
        (SELECT setting::bigint * 8192 FROM pg_settings WHERE name = 'shared_buffers')
    ) AS shared_buffers_bytes,
    (SELECT setting FROM pg_settings WHERE name = 'wal_buffers') AS wal_buffers_raw;

\echo ''
\echo '=== 4. Uso actual de work_mem potencial (conexiones activas x work_mem) ==='
SELECT
    count(*) AS conexiones_activas,
    (SELECT setting FROM pg_settings WHERE name='work_mem') AS work_mem_kb,
    pg_size_pretty(
        count(*) * (SELECT setting::bigint FROM pg_settings WHERE name='work_mem') * 1024
    ) AS work_mem_potencial_total
FROM pg_stat_activity
WHERE state = 'active';

\echo ''
\echo '=== 5. Parametros que requieren REINICIO vs solo RELOAD ==='
SELECT name, setting, context
FROM pg_settings
WHERE context IN ('postmaster','sighup')
  AND name IN ('shared_buffers','max_connections','wal_buffers',
               'work_mem','maintenance_work_mem','effective_cache_size')
ORDER BY context, name;

