-- Taller práctico: gestión de usuarios, roles y permisos en postgresql
-- Secciones 3 a 9: Gestión de Roles, Escenario Empresarial y Auditoría

\c postgres

-- Limpieza previa por si existen de una ejecución anterior
DROP DATABASE IF EXISTS empresa_db WITH (FORCE);
DROP ROLE IF EXISTS carlos, maria, pedro, ana;
DROP ROLE IF EXISTS gerentes, desarrolladores, analistas, lectores;
DROP ROLE IF EXISTS desarrollador, desarrollador_senior, usuario_app, admin_bd;
DROP ROLE IF EXISTS grupo_desarrolladores, grupo_lectores;

-- 3. Creación y Gestión de Roles
CREATE ROLE desarrollador;
CREATE ROLE usuario_app WITH LOGIN PASSWORD 'password123';
CREATE ROLE admin_bd WITH
    LOGIN
    PASSWORD 'admin123'
    CREATEDB
    CREATEROLE
    VALID UNTIL '2027-12-31';

-- Modificar roles existentes
ALTER ROLE usuario_app PASSWORD 'nueva_password123';
ALTER ROLE desarrollador CREATEDB;
ALTER ROLE desarrollador NOCREATEDB;
ALTER ROLE desarrollador RENAME TO desarrollador_senior;

-- Eliminar rol de prueba
DROP ROLE desarrollador_senior;

-- 6. Ejemplo Práctico Completo: Sistema de Gestión Empresarial
-- 1) Crear base de datos
CREATE DATABASE empresa_db;
\c empresa_db

-- 2) Crear roles de grupo
CREATE ROLE gerentes;
CREATE ROLE desarrolladores;
CREATE ROLE analistas;
CREATE ROLE lectores;

-- 3) Crear usuarios individuales
CREATE ROLE carlos WITH LOGIN PASSWORD 'carlos123';
CREATE ROLE maria WITH LOGIN PASSWORD 'maria123';
CREATE ROLE pedro WITH LOGIN PASSWORD 'pedro123';
CREATE ROLE ana WITH LOGIN PASSWORD 'ana123';

-- 4) Asignar usuarios a grupos
GRANT gerentes TO carlos;
GRANT desarrolladores TO maria;
GRANT analistas TO pedro;
GRANT lectores TO ana;

-- 5) Crear las tablas del escenario antes de asignar permisos sobre ellas
CREATE TABLE departamentos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    presupuesto DECIMAL(15,2)
);

CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    departamento_id INTEGER REFERENCES departamentos(id),
    salario DECIMAL(10,2)
);

CREATE TABLE proyectos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    fecha_inicio DATE,
    fecha_fin DATE
);

INSERT INTO departamentos (nombre, presupuesto) VALUES
('Tecnología', 250000.00),
('Ventas', 180000.00);

INSERT INTO empleados (nombre, email, departamento_id, salario) VALUES
('Laura Torres', 'laura@empresa.com', 1, 4500.00),
('Diego Vargas', 'diego@empresa.com', 2, 3800.00);

-- 6) Conceder privilegios a grupos
GRANT CONNECT ON DATABASE empresa_db TO gerentes, desarrolladores, analistas, lectores;
GRANT USAGE ON SCHEMA public TO gerentes, desarrolladores, analistas, lectores;

-- Gerentes: acceso completo
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gerentes;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gerentes;

-- Desarrolladores: lectura/escritura
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO desarrolladores;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO desarrolladores;

-- Analistas: lectura/escritura en tablas específicas
GRANT SELECT, INSERT, UPDATE ON empleados, departamentos TO analistas;

-- Lectores: solo lectura
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lectores;

-- Privilegios a nivel de columna para usuario_app
GRANT CONNECT ON DATABASE empresa_db TO usuario_app;
GRANT USAGE ON SCHEMA public TO usuario_app;
GRANT SELECT (id, nombre, email) ON empleados TO usuario_app;

-- 7. Consultas de Auditoría y Monitoreo
SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolcanlogin
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolname;

SELECT rolname FROM pg_roles WHERE rolcanlogin AND rolname NOT LIKE 'pg_%' ORDER BY rolname;

SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'empleados'
ORDER BY grantee, privilege_type;

SELECT
    u.rolname AS grupo,
    g.rolname AS miembro
FROM pg_auth_members m
JOIN pg_roles u ON (m.roleid = u.oid)
JOIN pg_roles g ON (m.member = g.oid)
WHERE u.rolname NOT LIKE 'pg_%'
ORDER BY 1, 2;

SELECT
    datname AS database,
    datacl AS privileges
FROM pg_database
WHERE datname = 'empresa_db';

-- 8. Buenas Prácticas y Seguridad
ALTER ROLE usuario_app VALID UNTIL '2026-12-31';
ALTER ROLE usuario_app CONNECTION LIMIT 10;

SELECT rolname, rolconnlimit, rolvaliduntil
FROM pg_roles
WHERE rolname = 'usuario_app';

