-- Taller práctico: backup y restore en postgresql (u6)
-- Paso 4: Configuración de WAL, Puntos de Restauración (PITR) y Monitoreo

\c tienda

-- 1. Revisar parámetros de WAL y archivado continuo
SELECT name, setting, context
FROM pg_settings
WHERE name IN ('wal_level', 'archive_mode', 'archive_command', 'archive_timeout', 'max_wal_senders')
ORDER BY name;

-- 2. Consultar LSN actual y archivo de segmento WAL activo
SELECT
    pg_current_wal_lsn() AS lsn_actual,
    pg_walfile_name(pg_current_wal_lsn()) AS archivo_segmento_wal;

-- 3. Crear un punto de restauración con nombre antes de un cambio crítico (PITR)
SELECT pg_create_restore_point('antes_migracion_precios_v2') AS lsn_restore_point;

-- 4. Consultar línea de tiempo (Timeline) y estado del último checkpoint en pg_control
SELECT
    timeline_id,
    checkpoint_lsn,
    redo_lsn,
    redo_wal_file,
    checkpoint_time
FROM pg_control_checkpoint();

-- 5. Monitorear estado del archivador de WAL (pg_stat_archiver)
SELECT
    archived_count,
    last_archived_wal,
    failed_count,
    last_failed_wal,
    stats_reset
FROM pg_stat_archiver;

