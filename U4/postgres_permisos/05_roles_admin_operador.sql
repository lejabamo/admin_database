-- =====================================================================
-- 05_ROLES_ADMIN_OPERADOR.SQL
-- Roles de ADMINISTRADOR (DBA) y OPERADOR de base de datos,
-- SIN usar SUPERUSER.
--
--  rol_dba_admin : administra la base: crea/modifica/borra objetos,
--                  gestiona roles y permisos, monitorea.
--  rol_operador  : operación diaria: monitoreo, cancelar/terminar
--                  sesiones, recargar configuración, mantenimiento.
--                  NO puede modificar estructura ni ver datos sensibles.
--  rol_backup    : lectura total para hacer pg_dump.
--
-- Roles predefinidos útiles de PostgreSQL:
--   pg_monitor         ver pg_stat_activity completo, estadísticas, config
--   pg_signal_backend  pg_cancel_backend / pg_terminate_backend
--   pg_read_all_data   SELECT en todo (PG14+)
--   pg_write_all_data  INSERT/UPDATE/DELETE en todo (PG14+)
--   pg_checkpoint      ejecutar CHECKPOINT (PG15+)
--   pg_maintain        VACUUM/ANALYZE/REINDEX/CLUSTER en todo (PG17+)
-- =====================================================================

\connect mydatabase

-- =====================================================================
-- A. ROL OPERADOR
-- =====================================================================
CREATE ROLE rol_operador NOLOGIN;

GRANT CONNECT, TEMPORARY ON DATABASE mydatabase TO rol_operador;

-- Monitoreo y control de sesiones
GRANT pg_monitor, pg_signal_backend TO rol_operador;

-- Puede leer datos NO sensibles (hereda lo del rol de lectura)
GRANT rol_lectura TO rol_operador;

-- Mantenimiento controlado mediante procedimiento SECURITY DEFINER
GRANT EXECUTE ON PROCEDURE myschema.sp_mantenimiento_analyze() TO rol_operador;

-- Recargar configuración (pg_hba.conf / postgresql.conf) sin reiniciar
GRANT EXECUTE ON FUNCTION pg_catalog.pg_reload_conf() TO rol_operador;

-- CHECKPOINT manual (PG15+)
GRANT pg_checkpoint TO rol_operador;

-- [PG17+] VACUUM / ANALYZE / REINDEX directo sobre las tablas:
-- GRANT MAINTAIN ON ALL TABLES IN SCHEMA myschema TO rol_operador;
-- o en todo el clúster:
-- GRANT pg_maintain TO rol_operador;

-- =====================================================================
-- B. ROL BACKUP (para pg_dump)
-- =====================================================================
CREATE ROLE rol_backup NOLOGIN;
GRANT CONNECT ON DATABASE mydatabase TO rol_backup;
GRANT pg_read_all_data TO rol_backup;          -- PG14+

-- =====================================================================
-- C. ROL ADMINISTRADOR (DBA)
-- =====================================================================
CREATE ROLE rol_dba_admin NOLOGIN;

-- 1. Todos los privilegios sobre la base, pudiendo delegarlos
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO rol_dba_admin WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON SCHEMA   myschema   TO rol_dba_admin WITH GRANT OPTION;

-- 2. Miembro del rol dueño: hereda la PROPIEDAD de todos los objetos
--    (ALTER, DROP, GRANT/REVOKE sobre cualquier tabla/función).
--    Para crear objetos nuevos debe hacer: SET ROLE app_owner;
--    así el dueño sigue siendo app_owner y aplican los DEFAULT PRIVILEGES.
GRANT app_owner TO rol_dba_admin;

-- 3. Monitoreo, sesiones, checkpoint y lectura/escritura global
GRANT pg_monitor, pg_signal_backend, pg_checkpoint TO rol_dba_admin;
GRANT pg_read_all_data, pg_write_all_data            TO rol_dba_admin;
-- [PG17+] GRANT pg_maintain TO rol_dba_admin;

-- 4. Poder asignar/quitar los roles de negocio a los usuarios
--    (ADMIN OPTION = puede hacer GRANT rol_x TO usuario)
GRANT rol_lectura, rol_escritura, rol_soporte, rol_rrhh,
      rol_operador, rol_backup
   TO rol_dba_admin WITH ADMIN OPTION;

-- 5. Ejecutar todas las funciones y procedimientos
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA myschema TO rol_dba_admin;
GRANT EXECUTE ON FUNCTION pg_catalog.pg_reload_conf() TO rol_dba_admin;

-- 6. [PG15+] Permitir cambiar parámetros concretos del servidor
--    sin ser superusuario
GRANT SET, ALTER SYSTEM ON PARAMETER log_min_duration_statement TO rol_dba_admin;
GRANT SET, ALTER SYSTEM ON PARAMETER work_mem                   TO rol_dba_admin;

-- NOTA: los ATRIBUTOS de rol (LOGIN, CREATEDB, CREATEROLE, SUPERUSER,
-- REPLICATION, BYPASSRLS) NO se heredan por membresía. Por eso
-- CREATEDB y CREATEROLE se dan directamente al usuario administrador
-- en 06_usuarios.sql.
