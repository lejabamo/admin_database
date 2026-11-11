-- =====================================================================
-- 02_PERMISOS_TABLAS.SQL
-- Permisos a nivel de ESQUEMA y de TABLA / SECUENCIA
--   Esquema:   USAGE (ver/usar objetos), CREATE (crear objetos)
--   Tabla:     SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES,
--              TRIGGER  (y MAINTAIN desde PG17)
--   Secuencia: USAGE, SELECT, UPDATE
-- =====================================================================

\connect mydatabase

-- ---------------------------------------------------------------------
-- 1. Permiso sobre el ESQUEMA (sin esto no ven ninguna tabla)
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA myschema TO rol_lectura, rol_escritura;

-- Si el rol debe crear sus propias tablas en el esquema:
-- GRANT CREATE ON SCHEMA myschema TO rol_escritura;

-- ---------------------------------------------------------------------
-- 2. Permisos sobre TODAS las tablas EXISTENTES del esquema
-- ---------------------------------------------------------------------
GRANT SELECT
   ON ALL TABLES IN SCHEMA myschema TO rol_lectura;

GRANT SELECT, INSERT, UPDATE, DELETE
   ON ALL TABLES IN SCHEMA myschema TO rol_escritura;

-- Las columnas SERIAL/BIGSERIAL usan secuencias: hace falta USAGE
-- para poder hacer INSERT (nextval). Las columnas IDENTITY no lo requieren.
GRANT USAGE, SELECT
   ON ALL SEQUENCES IN SCHEMA myschema TO rol_escritura;

-- ---------------------------------------------------------------------
-- 3. Permisos sobre UNA tabla específica / excepciones
-- ---------------------------------------------------------------------
-- La auditoría de salarios es sensible: la aplicación solo puede leerla
-- (nadie debe poder alterar el historial) y lectura no la ve.
REVOKE INSERT, UPDATE, DELETE ON myschema.auditoria_salarios FROM rol_escritura;
REVOKE ALL                    ON myschema.auditoria_salarios FROM rol_lectura;

-- Ejemplos de otros privilegios de tabla:
-- GRANT TRUNCATE   ON myschema.departamentos TO rol_x;  -- vaciar tabla
-- GRANT REFERENCES ON myschema.departamentos TO rol_x;  -- crear FK hacia ella
-- GRANT TRIGGER    ON myschema.departamentos TO rol_x;  -- crear triggers

-- Permitir que un rol a su vez conceda el permiso a otros:
-- GRANT SELECT ON myschema.departamentos TO rol_x WITH GRANT OPTION;

-- ---------------------------------------------------------------------
-- 4. Privilegios por defecto para tablas FUTURAS
--    IMPORTANTE: ALTER DEFAULT PRIVILEGES solo aplica a objetos creados
--    por el rol indicado en FOR ROLE (aquí el dueño app_owner). Si se
--    omite FOR ROLE, aplica solo a lo que cree quien ejecuta el comando.
-- ---------------------------------------------------------------------
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA myschema
    GRANT SELECT ON TABLES TO rol_lectura;

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA myschema
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rol_escritura;

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA myschema
    GRANT USAGE, SELECT ON SEQUENCES TO rol_escritura;
