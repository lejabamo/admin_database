-- =====================================================================
-- EJECUTAR_TODO.SQL
-- Ejecuta los scripts en orden. Desde la carpeta de los archivos:
--     psql -U postgres -f ejecutar_todo.sql
-- =====================================================================
\set ON_ERROR_STOP on

\i 00_preparacion.sql
\i 01_permisos_base_datos.sql
\i 02_permisos_tablas.sql
\i 03_permisos_columnas.sql
\i 04_permisos_funciones_procedimientos.sql
\i 05_roles_admin_operador.sql
\i 06_usuarios.sql
\i 07_verificacion.sql

-- Para borrar todo y volver a empezar:
-- \i 08_limpieza.sql
