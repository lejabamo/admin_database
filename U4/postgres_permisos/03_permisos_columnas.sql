-- =====================================================================
-- 03_PERMISOS_COLUMNAS.SQL
-- Permisos a nivel de COLUMNA: SELECT, INSERT, UPDATE, REFERENCES
--   GRANT SELECT (col1, col2) ON tabla TO rol;
--
-- REGLAS CLAVE:
--  * Un permiso a nivel de TABLA cubre TODAS las columnas. Si el rol ya
--    tiene SELECT sobre la tabla, dar/quitar permisos de columna no
--    cambia nada: primero hay que quitar el permiso de tabla.
--  * REVOKE a nivel de tabla también elimina los permisos de columna,
--    por eso el orden es: 1) REVOKE tabla  2) GRANT columnas.
--  * Con permisos de columna, "SELECT *" falla; hay que nombrar columnas.
--  * Un UPDATE ... WHERE id = x necesita también SELECT sobre "id".
-- =====================================================================

\connect mydatabase

-- ---------------------------------------------------------------------
-- 1. rol_lectura: puede ver empleados, pero NO salario ni numero_cuenta
-- ---------------------------------------------------------------------
REVOKE SELECT ON myschema.empleados FROM rol_lectura;   -- quitar permiso de tabla

GRANT SELECT (id_empleado, nombre, email, telefono,
              id_departamento, fecha_ingreso, activo)
   ON myschema.empleados TO rol_lectura;

-- ---------------------------------------------------------------------
-- 2. rol_soporte: mesa de ayuda. Ve datos de contacto y SOLO puede
--    modificar email y teléfono.
-- ---------------------------------------------------------------------
CREATE ROLE rol_soporte NOLOGIN;
GRANT CONNECT ON DATABASE mydatabase TO rol_soporte;
GRANT USAGE   ON SCHEMA myschema     TO rol_soporte;

GRANT SELECT (id_empleado, nombre, email, telefono)
   ON myschema.empleados TO rol_soporte;

GRANT UPDATE (email, telefono)
   ON myschema.empleados TO rol_soporte;

-- ---------------------------------------------------------------------
-- 3. rol_rrhh: Recursos Humanos. Ve todo, puede registrar empleados
--    (solo ciertas columnas) y cambiar departamento/estado, pero el
--    salario SOLO lo cambia mediante el procedimiento (archivo 04).
-- ---------------------------------------------------------------------
CREATE ROLE rol_rrhh NOLOGIN;
GRANT CONNECT ON DATABASE mydatabase TO rol_rrhh;
GRANT USAGE   ON SCHEMA myschema     TO rol_rrhh;

GRANT SELECT ON myschema.empleados, myschema.departamentos,
                myschema.auditoria_salarios TO rol_rrhh;

GRANT INSERT (nombre, email, telefono, id_departamento,
              salario, numero_cuenta, fecha_ingreso)
   ON myschema.empleados TO rol_rrhh;

GRANT UPDATE (id_departamento, activo)
   ON myschema.empleados TO rol_rrhh;

-- ---------------------------------------------------------------------
-- 4. Quitar un permiso de columna puntual
-- ---------------------------------------------------------------------
-- REVOKE UPDATE (telefono) ON myschema.empleados FROM rol_soporte;

-- ---------------------------------------------------------------------
-- Alternativa a permisos de columna: una VISTA con solo las columnas
-- permitidas (el usuario recibe SELECT sobre la vista, no la tabla).
-- ---------------------------------------------------------------------
-- CREATE VIEW myschema.v_directorio AS
--     SELECT nombre, email, telefono FROM myschema.empleados WHERE activo;
-- GRANT SELECT ON myschema.v_directorio TO rol_x;
