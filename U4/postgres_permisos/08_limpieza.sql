-- =====================================================================
-- 08_LIMPIEZA.SQL
-- Revoca y elimina todo lo creado (para volver a empezar).
-- Muestra el procedimiento correcto para borrar un rol que tiene
-- objetos o permisos: REASSIGN OWNED + DROP OWNED + DROP ROLE.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Ejemplo: eliminar UN usuario que tiene objetos/permisos en la base.
-- (REASSIGN/DROP OWNED se ejecutan en CADA base donde tenga algo)
-- ---------------------------------------------------------------------
-- \connect mydatabase
-- REASSIGN OWNED BY usr_x TO app_owner;  -- sus objetos pasan al dueño
-- DROP OWNED BY usr_x;                   -- quita todos sus permisos
-- DROP ROLE usr_x;

-- ---------------------------------------------------------------------
-- Limpieza total
-- ---------------------------------------------------------------------
\connect postgres

-- Permisos a nivel de clúster (no se borran con la base de datos)
REVOKE SET, ALTER SYSTEM ON PARAMETER log_min_duration_statement FROM rol_dba_admin;
REVOKE SET, ALTER SYSTEM ON PARAMETER work_mem                   FROM rol_dba_admin;

DROP DATABASE IF EXISTS mydatabase WITH (FORCE);   -- FORCE: PG13+

DROP ROLE IF EXISTS usr_reportes, usr_app, usr_soporte, usr_rrhh,
                    dba_admin1, usr_operador1, usr_backup;

DROP ROLE IF EXISTS rol_dba_admin, rol_operador, rol_backup,
                    rol_rrhh, rol_soporte, rol_escritura, rol_lectura,
                    app_owner;
