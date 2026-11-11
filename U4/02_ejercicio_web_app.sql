-- Taller práctico: gestión de usuarios, roles y permisos en postgresql
-- Sección 10: Ejercicio Práctico 1 - Estructura para Aplicación Web

\c empresa_db

DROP ROLE IF EXISTS usr_web_cliente, usr_web_backend, usr_web_root;
DROP ROLE IF EXISTS web_app, web_user, web_admin;

-- 1. Crear los tres roles solicitados en el Ejercicio 1
-- web_app: sin login (rol de grupo para la capa de aplicación)
CREATE ROLE web_app NOLOGIN;

-- web_user: rol para usuarios regulares (solo consulta sobre catálogos/datos públicos)
CREATE ROLE web_user NOLOGIN;

-- web_admin: rol para administradores de la aplicación
CREATE ROLE web_admin NOLOGIN CREATEDB CREATEROLE;

-- 2. Asignar privilegios sobre empresa_db y el esquema public
GRANT CONNECT ON DATABASE empresa_db TO web_app, web_user, web_admin;
GRANT USAGE ON SCHEMA public TO web_app, web_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO web_admin;

-- web_user: solo lectura en proyectos y columnas no sensibles de empleados
GRANT SELECT ON proyectos, departamentos TO web_user;
GRANT SELECT (id, nombre, email, departamento_id) ON empleados TO web_user;

-- web_app: lectura y escritura operativa en las tablas de la aplicación y uso de secuencias
GRANT SELECT, INSERT, UPDATE ON proyectos, departamentos, empleados TO web_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_app;

-- web_admin: control total de tablas y secuencias
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO web_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO web_admin;

-- 3. Crear cuentas con LOGIN asociadas a cada rol para validar su funcionamiento
CREATE ROLE usr_web_backend WITH LOGIN PASSWORD 'WebApp_2026' IN ROLE web_app;
CREATE ROLE usr_web_cliente WITH LOGIN PASSWORD 'WebUser_2026' IN ROLE web_user;
CREATE ROLE usr_web_root    WITH LOGIN PASSWORD 'WebAdmin_2026' IN ROLE web_admin;

-- 4. Verificar permisos efectivos
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privilegios
FROM information_schema.role_table_grants
WHERE grantee IN ('web_app', 'web_user', 'web_admin')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

