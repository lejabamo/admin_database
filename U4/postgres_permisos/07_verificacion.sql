-- =====================================================================
-- 07_VERIFICACION.SQL
-- Consultas para revisar quién tiene qué permiso, y pruebas.
-- =====================================================================

\connect mydatabase

-- ---------------------------------------------------------------------
-- Comandos rápidos de psql
--   \du+            roles, atributos y membresías
--   \l+             bases de datos y sus permisos
--   \dn+            esquemas y sus permisos
--   \dp myschema.*  permisos de tablas y columnas
--   \ddp            privilegios por defecto
--   \df+ myschema.* funciones/procedimientos y sus permisos
-- ---------------------------------------------------------------------

-- 1. Roles, atributos y a qué roles pertenecen
SELECT r.rolname, r.rolcanlogin AS login, r.rolsuper AS superuser,
       r.rolcreatedb AS createdb, r.rolcreaterole AS createrole,
       r.rolconnlimit AS conn_limit, r.rolvaliduntil AS vence,
       ARRAY(SELECT g.rolname
             FROM pg_auth_members m JOIN pg_roles g ON g.oid = m.roleid
             WHERE m.member = r.oid ORDER BY 1) AS miembro_de
FROM   pg_roles r
WHERE  r.rolname !~ '^pg_'
ORDER  BY r.rolcanlogin, r.rolname;

-- 2. Permisos sobre tablas
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privilegios
FROM   information_schema.role_table_grants
WHERE  table_schema = 'myschema' AND grantee <> 'app_owner'
GROUP  BY grantee, table_name
ORDER  BY grantee, table_name;

-- 3. Permisos sobre columnas (solo los dados a nivel de columna)
SELECT a.attrelid::regclass AS tabla, a.attname AS columna, a.attacl AS permisos
FROM   pg_attribute a
WHERE  a.attrelid = 'myschema.empleados'::regclass AND a.attacl IS NOT NULL
ORDER  BY a.attnum;

-- 4. Permisos sobre funciones y procedimientos
SELECT p.oid::regprocedure AS rutina,
       CASE p.prokind WHEN 'f' THEN 'función' WHEN 'p' THEN 'procedimiento' END AS tipo,
       CASE WHEN p.prosecdef THEN 'DEFINER' ELSE 'INVOKER' END AS seguridad,
       p.proacl AS permisos
FROM   pg_proc p
WHERE  p.pronamespace = 'myschema'::regnamespace
ORDER  BY 1;

-- 5. Preguntas directas: ¿el usuario X puede hacer Y?
SELECT 'usr_reportes CONNECT mydatabase'   AS prueba, has_database_privilege('usr_reportes', 'mydatabase', 'CONNECT') AS puede
UNION ALL SELECT 'usr_reportes SELECT empleados (tabla)', has_table_privilege('usr_reportes', 'myschema.empleados', 'SELECT')
UNION ALL SELECT 'usr_reportes SELECT empleados.nombre',  has_column_privilege('usr_reportes', 'myschema.empleados', 'nombre',  'SELECT')
UNION ALL SELECT 'usr_reportes SELECT empleados.salario', has_column_privilege('usr_reportes', 'myschema.empleados', 'salario', 'SELECT')
UNION ALL SELECT 'usr_soporte UPDATE empleados.telefono', has_column_privilege('usr_soporte', 'myschema.empleados', 'telefono', 'UPDATE')
UNION ALL SELECT 'usr_soporte UPDATE empleados.salario',  has_column_privilege('usr_soporte', 'myschema.empleados', 'salario', 'UPDATE')
UNION ALL SELECT 'usr_rrhh EXECUTE sp_aumentar_salario',  has_function_privilege('usr_rrhh', 'myschema.sp_aumentar_salario(integer,numeric)', 'EXECUTE')
UNION ALL SELECT 'usr_reportes EXECUTE fn_total_nomina',  has_function_privilege('usr_reportes', 'myschema.fn_total_nomina(integer)', 'EXECUTE')
UNION ALL SELECT 'usr_operador1 EXECUTE sp_mantenimiento', has_function_privilege('usr_operador1', 'myschema.sp_mantenimiento_analyze()', 'EXECUTE');

-- ---------------------------------------------------------------------
-- 6. Pruebas en vivo (SET ROLE simula ser ese usuario; como superusuario)
--    \set ON_ERROR_STOP off  para que los errores esperados no detengan psql
-- ---------------------------------------------------------------------
\set ON_ERROR_STOP off

SET ROLE usr_reportes;
SELECT nombre, email FROM myschema.empleados;           -- OK
SELECT nombre, salario FROM myschema.empleados;         -- ERROR: sin permiso en salario
SELECT * FROM myschema.fn_empleados_por_departamento(1); -- OK
RESET ROLE;

SET ROLE usr_soporte;
UPDATE myschema.empleados SET telefono = '3009990000' WHERE id_empleado = 1;  -- OK
UPDATE myschema.empleados SET salario  = 1            WHERE id_empleado = 1;  -- ERROR
RESET ROLE;

SET ROLE usr_rrhh;
SELECT myschema.fn_total_nomina();                                   -- OK
UPDATE myschema.empleados SET salario = 9999999 WHERE id_empleado = 2; -- ERROR: no directo
CALL myschema.sp_aumentar_salario(2, 10);                            -- OK: vía procedimiento
CALL myschema.sp_aumentar_salario(2, 50);                            -- ERROR: regla de negocio
RESET ROLE;

SET ROLE usr_operador1;
SELECT pid, usename, state, left(query, 40) AS query FROM pg_stat_activity;  -- OK
CALL myschema.sp_mantenimiento_analyze();                            -- OK
DROP TABLE myschema.departamentos;                                   -- ERROR
RESET ROLE;

SET ROLE dba_admin1;
SET ROLE app_owner;                                                  -- actuar como dueño
CREATE TABLE myschema.proyectos (id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, nombre TEXT);
RESET ROLE;
-- La tabla nueva ya tiene permisos gracias a ALTER DEFAULT PRIVILEGES:
SELECT has_table_privilege('usr_reportes', 'myschema.proyectos', 'SELECT') AS lectura_ve_proyectos,
       has_table_privilege('usr_app',      'myschema.proyectos', 'INSERT') AS app_inserta_proyectos;

\set ON_ERROR_STOP on
