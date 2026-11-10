-- ============================================================
-- 05_procesos_utilitarios.sql
-- Objetivo: ver los procesos backend/utilitarios vivos en el
-- servidor (equivalente SQL a mirar el diagrama de arquitectura).
-- ============================================================

\echo '=== 1. Procesos activos vistos por PostgreSQL ==='
SELECT pid, backend_type, state, wait_event_type, wait_event,
       query_start, left(query, 60) AS query_recortada
FROM pg_stat_activity
ORDER BY backend_type, pid;

\echo ''
\echo '=== 2. Resumen de procesos por tipo (Writer, WAL Writer, Checkpointer, etc.) ==='
SELECT backend_type, count(*) AS cantidad
FROM pg_stat_activity
GROUP BY backend_type
ORDER BY backend_type;

\echo ''
\echo '=== 3. Conexiones actuales vs limite maximo ==='
SELECT
    (SELECT count(*) FROM pg_stat_activity) AS conexiones_actuales,
    (SELECT setting FROM pg_settings WHERE name = 'max_connections') AS max_connections;

