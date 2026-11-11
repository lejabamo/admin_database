-- =====================================================================
-- 04_PERMISOS_FUNCIONES_PROCEDIMIENTOS.SQL
-- Permiso EXECUTE sobre funciones (SELECT fn()) y procedimientos (CALL sp())
--
-- IMPORTANTE: PostgreSQL da EXECUTE a PUBLIC por defecto en toda
-- función/procedimiento nuevo. Si no se revoca, CUALQUIER usuario
-- conectado puede ejecutarlos.
--
--  SECURITY INVOKER (defecto): se ejecuta con permisos de quien llama.
--  SECURITY DEFINER          : se ejecuta con permisos del dueño.
-- =====================================================================

\connect mydatabase

-- ---------------------------------------------------------------------
-- 1. Quitar EXECUTE a PUBLIC en lo que ya existe
-- ---------------------------------------------------------------------
REVOKE EXECUTE ON ALL FUNCTIONS  IN SCHEMA myschema FROM PUBLIC;
REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA myschema FROM PUBLIC;
-- (también existe: ON ALL ROUTINES IN SCHEMA = funciones + procedimientos)

-- ... y en lo que se cree en el FUTURO.
-- OJO: se hace SIN "IN SCHEMA". Los privilegios por defecto por esquema
-- solo SUMAN a los globales, no pueden quitar el EXECUTE global a PUBLIC.
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;    -- FUNCTIONS incluye procedimientos

-- ---------------------------------------------------------------------
-- 2. EXECUTE sobre una FUNCIÓN específica (se indica la firma: tipos
--    de los parámetros, porque puede haber sobrecarga)
-- ---------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION myschema.fn_empleados_por_departamento(INTEGER)
   TO rol_lectura, rol_escritura, rol_rrhh;

GRANT EXECUTE ON FUNCTION myschema.fn_total_nomina(INTEGER)
   TO rol_rrhh;
-- Si se le diera a rol_lectura, igual fallaría: es SECURITY INVOKER y
-- rol_lectura no puede leer la columna salario.

-- ---------------------------------------------------------------------
-- 3. EXECUTE sobre un PROCEDIMIENTO específico
--    rol_rrhh NO tiene UPDATE sobre salario, pero puede aumentarlo
--    mediante este procedimiento SECURITY DEFINER (con sus validaciones
--    y registro en auditoría).
-- ---------------------------------------------------------------------
GRANT EXECUTE ON PROCEDURE myschema.sp_aumentar_salario(INTEGER, NUMERIC)
   TO rol_rrhh;

-- ---------------------------------------------------------------------
-- 4. EXECUTE sobre TODAS las funciones del esquema + futuras
-- ---------------------------------------------------------------------
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA myschema TO rol_escritura;

-- (en ALTER DEFAULT PRIVILEGES "FUNCTIONS" incluye también los
--  procedimientos futuros; en GRANT ... ALL FUNCTIONS no)
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA myschema
    GRANT EXECUTE ON FUNCTIONS TO rol_escritura;

-- ---------------------------------------------------------------------
-- 5. Quitar un permiso de ejecución
-- ---------------------------------------------------------------------
-- REVOKE EXECUTE ON PROCEDURE myschema.sp_aumentar_salario(INTEGER, NUMERIC) FROM rol_rrhh;
