-- ============================================================================
-- TALLER PRÁCTICO: BACKUP Y RESTORE EN POSTGRESQL (U6)
-- Paso 1: Preparar la base de datos de práctica 'tienda' (50 000 pedidos)
-- ============================================================================

\c postgres
DROP DATABASE IF EXISTS tienda WITH (FORCE);
CREATE DATABASE tienda;
\c tienda

CREATE SCHEMA ventas;

CREATE TABLE public.clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    ciudad VARCHAR(60) NOT NULL,
    fecha_registro DATE DEFAULT CURRENT_DATE
);

CREATE TABLE ventas.pedidos (
    id_pedido BIGSERIAL PRIMARY KEY,
    id_cliente INT NOT NULL REFERENCES public.clientes(id_cliente),
    fecha TIMESTAMP NOT NULL,
    estado VARCHAR(30) NOT NULL,
    total NUMERIC(10,2) NOT NULL
);

CREATE TABLE public.logs_auditoria (
    id_log BIGSERIAL PRIMARY KEY,
    evento TEXT NOT NULL,
    fecha TIMESTAMP DEFAULT NOW()
);

SELECT setseed(0.35);

INSERT INTO public.clientes (nombre, email, ciudad)
SELECT
    'Cliente ' || g,
    'cliente' || g || '@correo.com',
    (ARRAY['Bogotá', 'Cali', 'Medellín', 'Barranquilla'])[floor(random()*4+1)]
FROM generate_series(1, 500) AS g;

INSERT INTO ventas.pedidos (id_cliente, fecha, estado, total)
SELECT
    (random() * 499)::int + 1,
     TIMESTAMP '2026-01-01 08:00:00' + (random() * 250 || ' days')::interval,
    (ARRAY['completado', 'enviado', 'procesando'])[floor(random()*3+1)],
    round((random() * 450 + 20)::numeric, 2)
FROM generate_series(1, 50000);

INSERT INTO public.logs_auditoria (evento)
SELECT 'Registro de evento #' || g FROM generate_series(1, 2000) AS g;

SELECT
    schemaname,
    relname AS tabla,
    n_live_tup AS filas_aprox,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) AS tamano_total
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||relname) DESC;

SELECT pg_size_pretty(pg_database_size('tienda')) AS tamano_base_tienda;
