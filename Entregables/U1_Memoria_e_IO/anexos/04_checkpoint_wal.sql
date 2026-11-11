-- 04_checkpoint_wal.sql
-- Objetivo: entender la configuracion de checkpoints y WAL,
-- que impactan directamente el I/O de escritura.

\echo '--- 1. Parametros de checkpoint ---'
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'checkpoint_timeout',
    'checkpoint_completion_target',
    'max_wal_size',
    'min_wal_size',
    'checkpoint_warning',
    'checkpoint_flush_after'
)
ORDER BY name;

\echo ''
\echo '--- 2. Parametros de WAL / durabilidad ---'
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'wal_level',
    'wal_buffers',
    'wal_writer_delay',
    'wal_writer_flush_after',
    'synchronous_commit',
    'fsync',
    'full_page_writes'
)
ORDER BY name;

\echo ''
\echo '--- 3. Ultimo checkpoint ejecutado y motivo ---'
SELECT * FROM pg_control_checkpoint();

\echo ''
\echo '--- 4. Autovacuum: parametros basicos ---'
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'autovacuum',
    'autovacuum_max_workers',
    'autovacuum_naptime',
    'autovacuum_vacuum_scale_factor',
    'autovacuum_analyze_scale_factor'
)
ORDER BY name;

