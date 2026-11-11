-- =====================================================================
-- 01_PERMISOS_BASE_DATOS.SQL
-- Permisos a nivel de BASE DE DATOS: CONNECT, TEMPORARY, CREATE
--   CONNECT    -> poder conectarse a la base
--   TEMPORARY  -> crear tablas temporales
--   CREATE     -> crear ESQUEMAS nuevos dentro de la base
--
-- Recuerde: para leer una tabla se necesita permiso en los 3 niveles:
--   BASE DE DATOS (CONNECT) -> ESQUEMA (USAGE) -> TABLA (SELECT...)
-- =====================================================================

\connect mydatabase

-- ---------------------------------------------------------------------
-- 1. Quitar lo que el pseudo-rol PUBLIC (todos los usuarios) recibe
--    por defecto
-- ---------------------------------------------------------------------
REVOKE ALL    ON DATABASE mydatabase FROM PUBLIC;   -- quita CONNECT y TEMPORARY
REVOKE CREATE ON SCHEMA public       FROM PUBLIC;   -- necesario en PG14 o anterior
                                                    -- (desde PG15 ya viene revocado)
REVOKE ALL    ON SCHEMA myschema     FROM PUBLIC;

-- ---------------------------------------------------------------------
-- 2. Roles de grupo (NOLOGIN): los permisos se dan a ROLES,
--    y luego los usuarios se hacen miembros de esos roles.
-- ---------------------------------------------------------------------
CREATE ROLE rol_lectura   NOLOGIN;   -- solo consulta
CREATE ROLE rol_escritura NOLOGIN;   -- la aplicación: CRUD

-- ---------------------------------------------------------------------
-- 3. Permisos sobre la base de datos
-- ---------------------------------------------------------------------
GRANT CONNECT            ON DATABASE mydatabase TO rol_lectura;
GRANT CONNECT, TEMPORARY ON DATABASE mydatabase TO rol_escritura;

-- Ejemplo: permitir que un rol cree esquemas nuevos en la base
-- GRANT CREATE ON DATABASE mydatabase TO rol_escritura;

-- ---------------------------------------------------------------------
-- 4. Configuración a nivel de base de datos
-- ---------------------------------------------------------------------
ALTER DATABASE mydatabase CONNECTION LIMIT 100;           -- máximo de conexiones
ALTER DATABASE mydatabase SET search_path = myschema, public;

-- OJO: los ALTER ROLE ... SET (search_path, timeouts, etc.) NO se
-- heredan de un rol de grupo a sus miembros. Esos ajustes se ponen
-- sobre el USUARIO que inicia sesión (ver 06_usuarios.sql).
