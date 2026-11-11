-- 03_io_estadisticas.sql
-- Objetivo: revisar cuanto se esta leyendo desde cache (shared
-- buffers) vs disco, y el detalle de IO por proceso (PG >= 16).

\echo '--- 1. Cache hit ratio a nivel de base de datos ---'
-- Un valor cercano a 99% es deseable; valores bajos sugieren
-- shared_buffers insuficiente o consultas que barren mucho disco.
SELECT
    datname,
    blks_read,
    blks_hit,
    round( (blks_hit::numeric / NULLIF(blks_hit + blks_read, 0)) * 100, 2) AS cache_hit_ratio_pct
FROM pg_stat_database
WHERE datname = current_database();

\echo ''
\echo '--- 2. Cache hit ratio por tabla (top 15 con mas actividad de IO) ---'
SELECT
    schemaname,
    relname,
    heap_blks_read,
    heap_blks_hit,
    round( (heap_blks_hit::numeric / NULLIF(heap_blks_hit + heap_blks_read, 0)) * 100, 2) AS cache_hit_pct
FROM pg_statio_user_tables
ORDER BY (heap_blks_read + heap_blks_hit) DESC
LIMIT 15;

\echo ''
\echo '--- 3. Actividad del Background Writer / Checkpointer ---'
-- Disponible como vista consolidada en versiones anteriores a la 17;
-- si tu version es >= 17, usar pg_stat_checkpointer (ver bloque 5).
SELECT * FROM pg_stat_bgwriter;

\echo ''
\echo '--- 4. IO detallado por tipo de backend (PostgreSQL 16+) ---'
-- pg_stat_io existe desde PG 16. Si tu version es menor, este bloque
-- devolvera error "relation does not exist": es normal, coméntenlo.
SELECT backend_type, object, context,
       reads, writes, extends, hits,
       fsyncs
FROM pg_stat_io
ORDER BY backend_type, object;

\echo ''
\echo '--- 5. Checkpointer separado (PostgreSQL 17+) ---'
-- Descomentar si su version es 17 o superior.
-- SELECT * FROM pg_stat_checkpointer;

\echo ''
\echo '--- 6. Consultas mas costosas en IO (requiere extension pg_stat_statements) ---'
-- Si no esta instalada, este bloque devuelve error; se explica en la guia
-- como habilitarla (shared_preload_libraries = 'pg_stat_statements').
SELECT
    round(total_exec_time::numeric, 2) AS tiempo_total_ms,
    calls,
    round((shared_blks_read + shared_blks_hit)::numeric, 0) AS bloques_totales,
    shared_blks_read,
    shared_blks_hit,
    query
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 10;

