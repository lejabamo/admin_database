-- 02_ubicacion_archivos.sql
-- Objetivo: ubicar en disco el data directory, los archivos de
-- configuracion, el WAL, los logs y los tablespaces.

\echo '--- 1. Directorio de datos (PGDATA) ---'
SHOW data_directory;

\echo ''
\echo '--- 2. Archivos de configuracion principales ---'
SELECT name, setting
FROM pg_settings
WHERE name IN ('config_file','hba_file','ident_file','data_directory',
               'external_pid_file','log_directory','log_filename',
               'stats_temp_directory');

\echo ''
\echo '--- 3. Ubicacion logica de los WAL (pg_wal) ---'
SHOW data_directory;
\echo 'El WAL vive normalmente en <data_directory>/pg_wal'
SELECT pg_current_wal_lsn() AS lsn_actual,
       pg_walfile_name(pg_current_wal_lsn()) AS archivo_wal_actual;

\echo ''
\echo '--- 4. Tablespaces definidos ---'
SELECT spcname, pg_tablespace_location(oid) AS ubicacion
FROM pg_tablespace;

\echo ''
\echo '--- 5. Tamaño de la base de datos actual y de sus principales objetos ---'
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamano_bd;

SELECT
    schemaname,
    relname,
    pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total,
    pg_size_pretty(pg_relation_size(relid)) AS tamano_tabla,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS indices_y_toast
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 15;

\echo ''
\echo '--- 6. Archivo de log activo (si logging_collector esta activo) ---'
SHOW logging_collector;
SHOW log_destination;

