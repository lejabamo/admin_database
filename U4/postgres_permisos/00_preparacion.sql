-- =====================================================================
-- 00_PREPARACION.SQL
-- Crea el rol propietario, la base de datos, el esquema y objetos de
-- ejemplo (tablas, funciones y procedimientos) sobre los que luego
-- se darán permisos.
--
-- Ejecutar como superusuario:   psql -U postgres -f 00_preparacion.sql
-- Probado en PostgreSQL 16 (compatible con 15+; ver notas por versión)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Rol DUEÑO de los objetos (sin login).
--    Buena práctica: nadie inicia sesión como dueño; los objetos
--    pertenecen a un rol "técnico" y los administradores se vuelven
--    miembros de él. Así nunca quedan tablas "huérfanas" de un usuario.
-- ---------------------------------------------------------------------
CREATE ROLE app_owner NOLOGIN;

-- ---------------------------------------------------------------------
-- 2. Base de datos y esquema
-- ---------------------------------------------------------------------
CREATE DATABASE mydatabase OWNER app_owner;

\connect mydatabase

CREATE SCHEMA myschema AUTHORIZATION app_owner;

-- ---------------------------------------------------------------------
-- 3. Crear los objetos COMO app_owner para que él sea el propietario
-- ---------------------------------------------------------------------
SET ROLE app_owner;

CREATE TABLE myschema.departamentos (
    id_departamento  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE myschema.empleados (
    id_empleado      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre           VARCHAR(100)  NOT NULL,
    email            VARCHAR(150)  NOT NULL UNIQUE,
    telefono         VARCHAR(30),
    id_departamento  INTEGER REFERENCES myschema.departamentos (id_departamento),
    salario          NUMERIC(12,2) NOT NULL,          -- dato sensible
    numero_cuenta    VARCHAR(30),                     -- dato sensible
    fecha_ingreso    DATE          NOT NULL DEFAULT CURRENT_DATE,
    activo           BOOLEAN       NOT NULL DEFAULT TRUE
);

CREATE TABLE myschema.auditoria_salarios (
    id                BIGSERIAL PRIMARY KEY,           -- usa una secuencia
    id_empleado       INTEGER       NOT NULL,
    salario_anterior  NUMERIC(12,2),
    salario_nuevo     NUMERIC(12,2),
    modificado_por    TEXT          NOT NULL DEFAULT session_user,
    fecha             TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Datos de ejemplo
INSERT INTO myschema.departamentos (nombre)
VALUES ('Sistemas'), ('Ventas'), ('Recursos Humanos');

INSERT INTO myschema.empleados (nombre, email, telefono, id_departamento, salario, numero_cuenta)
VALUES ('Ana Gómez',    'ana@empresa.com',    '3001112233', 1, 5500000, '001-123456'),
       ('Luis Pérez',   'luis@empresa.com',   '3014445566', 2, 3200000, '001-654321'),
       ('Marta Ruiz',   'marta@empresa.com',  '3027778899', 3, 4100000, '002-111222'),
       ('Carlos Díaz',  'carlos@empresa.com', '3150001122', 1, 6200000, '002-333444');

-- ---------------------------------------------------------------------
-- 4. FUNCIONES
-- ---------------------------------------------------------------------

-- 4.1 Función SECURITY INVOKER (por defecto): se ejecuta con los
--     permisos de QUIEN LA LLAMA. Solo lee columnas no sensibles.
CREATE FUNCTION myschema.fn_empleados_por_departamento(p_id_departamento INTEGER)
RETURNS TABLE (id_empleado INTEGER, nombre VARCHAR, email VARCHAR)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
    SELECT e.id_empleado, e.nombre, e.email
    FROM   myschema.empleados e
    WHERE  e.id_departamento = p_id_departamento
      AND  e.activo;
$$;

-- 4.2 Función que lee el salario. Como es SECURITY INVOKER, aunque
--     alguien tenga EXECUTE, fallará si no puede leer la columna salario.
CREATE FUNCTION myschema.fn_total_nomina(p_id_departamento INTEGER DEFAULT NULL)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
    SELECT COALESCE(SUM(salario), 0)
    FROM   myschema.empleados
    WHERE  activo
      AND  (p_id_departamento IS NULL OR id_departamento = p_id_departamento);
$$;

-- ---------------------------------------------------------------------
-- 5. PROCEDIMIENTOS
-- ---------------------------------------------------------------------

-- 5.1 Procedimiento SECURITY DEFINER: se ejecuta con los permisos del
--     DUEÑO (app_owner). Permite que un rol SIN permiso de UPDATE sobre
--     "salario" pueda subir sueldos, pero solo con estas reglas.
--     ¡Siempre fijar search_path en funciones SECURITY DEFINER!
CREATE PROCEDURE myschema.sp_aumentar_salario(p_id_empleado INTEGER, p_porcentaje NUMERIC)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = myschema, pg_temp
AS $$
DECLARE
    v_anterior NUMERIC(12,2);
    v_nuevo    NUMERIC(12,2);
BEGIN
    IF p_porcentaje IS NULL OR p_porcentaje <= 0 OR p_porcentaje > 30 THEN
        RAISE EXCEPTION 'Porcentaje inválido: % (debe estar entre 0 y 30)', p_porcentaje;
    END IF;

    SELECT salario INTO v_anterior
    FROM   empleados
    WHERE  id_empleado = p_id_empleado
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el empleado %', p_id_empleado;
    END IF;

    v_nuevo := ROUND(v_anterior * (1 + p_porcentaje / 100), 2);

    UPDATE empleados SET salario = v_nuevo WHERE id_empleado = p_id_empleado;

    INSERT INTO auditoria_salarios (id_empleado, salario_anterior, salario_nuevo)
    VALUES (p_id_empleado, v_anterior, v_nuevo);

    RAISE NOTICE 'Empleado %: % -> %', p_id_empleado, v_anterior, v_nuevo;
END;
$$;

-- 5.2 Procedimiento de mantenimiento (lo usará el rol OPERADOR).
--     Antes de PG17 solo el dueño puede hacer ANALYZE/VACUUM de una
--     tabla; con SECURITY DEFINER se lo delegamos de forma controlada.
CREATE PROCEDURE myschema.sp_mantenimiento_analyze()
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = myschema, pg_temp
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'myschema' LOOP
        EXECUTE format('ANALYZE myschema.%I', r.tablename);
        RAISE NOTICE 'ANALYZE myschema.% completado', r.tablename;
    END LOOP;
END;
$$;

RESET ROLE;
