-- =====================================================================
-- 06_USUARIOS.SQL
-- Usuarios con LOGIN y asignación de roles.
--   CREATE USER = CREATE ROLE ... WITH LOGIN
--   IN ROLE x   = lo hace miembro del rol x (equivale a GRANT x TO usuario)
--
-- Contraseñas: cámbielas. En psql es más seguro usar  \password usuario
-- para que la clave no quede en el historial ni en los logs.
-- =====================================================================

\connect mydatabase

-- ---------------------------------------------------------------------
-- 1. Usuarios de negocio
-- ---------------------------------------------------------------------
CREATE USER usr_reportes WITH PASSWORD 'Cambiar_Reportes_2026'
    CONNECTION LIMIT 5
    IN ROLE rol_lectura;

CREATE USER usr_app WITH PASSWORD 'Cambiar_App_2026'
    CONNECTION LIMIT 50
    IN ROLE rol_escritura;

CREATE USER usr_soporte WITH PASSWORD 'Cambiar_Soporte_2026'
    IN ROLE rol_soporte;

CREATE USER usr_rrhh WITH PASSWORD 'Cambiar_Rrhh_2026'
    VALID UNTIL '2027-12-31'          -- la clave vence en esa fecha
    IN ROLE rol_rrhh;

-- ---------------------------------------------------------------------
-- 2. Usuarios de administración y operación
-- ---------------------------------------------------------------------
-- El DBA recibe CREATEDB y CREATEROLE directamente (no se heredan)
CREATE USER dba_admin1 WITH PASSWORD 'Cambiar_Dba_2026'
    CREATEDB CREATEROLE
    IN ROLE rol_dba_admin;

CREATE USER usr_operador1 WITH PASSWORD 'Cambiar_Operador_2026'
    IN ROLE rol_operador;

CREATE USER usr_backup WITH PASSWORD 'Cambiar_Backup_2026'
    IN ROLE rol_backup;

-- ---------------------------------------------------------------------
-- 3. Ajustes por usuario (se ponen al USUARIO, no al rol de grupo)
-- ---------------------------------------------------------------------
ALTER ROLE usr_reportes SET default_transaction_read_only = on;
ALTER ROLE usr_reportes SET statement_timeout = '60s';
ALTER ROLE usr_app      IN DATABASE mydatabase SET search_path = myschema, public;
ALTER ROLE usr_app      SET idle_in_transaction_session_timeout = '5min';

-- ---------------------------------------------------------------------
-- 4. Otras operaciones comunes con usuarios
-- ---------------------------------------------------------------------
-- Dar un rol adicional a un usuario ya creado:
-- GRANT rol_soporte TO usr_reportes;

-- Quitar un rol:
-- REVOKE rol_soporte FROM usr_reportes;

-- Bloquear / desbloquear el acceso sin borrar el usuario:
-- ALTER ROLE usr_soporte NOLOGIN;
-- ALTER ROLE usr_soporte LOGIN;

-- Cambiar contraseña:
-- ALTER ROLE usr_app WITH PASSWORD 'NuevaClave_2026';

-- Usuario miembro de un rol pero que NO hereda automáticamente sus
-- permisos (debe hacer SET ROLE rol_x para usarlos):
-- CREATE USER usr_auditor WITH PASSWORD '...' NOINHERIT IN ROLE rol_rrhh;
