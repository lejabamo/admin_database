-- Taller: particionamiento y carga de datos en postgresql 15+
-- Parte 1: Particionamiento (Pasos 1 a 9)

\c postgres
DROP DATABASE IF EXISTS taller_particiones;
CREATE DATABASE taller_particiones;
\c taller_particiones
\timing on

-- Paso 1: Tabla base sin particionar
CREATE TABLE ventas_sin_particion (
    id bigint GENERATED ALWAYS AS IDENTITY,
    fecha date NOT NULL,
    region text NOT NULL,
    monto numeric(10,2),
    PRIMARY KEY (id)
);

-- Paso 2: Tabla particionada por RANGE (fecha)
CREATE TABLE ventas (
    id bigint GENERATED ALWAYS AS IDENTITY,
    fecha date NOT NULL,
    region text NOT NULL,
    monto numeric(10,2),
    PRIMARY KEY (id, fecha)
) PARTITION BY RANGE (fecha);

-- Paso 3: Tres particiones mensuales y una DEFAULT
CREATE TABLE ventas_2026_01 PARTITION OF ventas
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE ventas_2026_02 PARTITION OF ventas
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE ventas_2026_03 PARTITION OF ventas
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE ventas_otros PARTITION OF ventas DEFAULT;

\d+ ventas

-- Paso 4: Insertar 50 000 filas de prueba entre enero y marzo de 2026
SELECT setseed(0.42);
INSERT INTO ventas (fecha, region, monto)
SELECT
    date '2026-01-01' + (random() * 89)::int,
    (ARRAY['norte','sur','centro'])[floor(random()*3+1)],
    round((random()*500)::numeric, 2)
FROM generate_series(1, 50000);

SELECT tableoid::regclass, count(*)
FROM ventas
GROUP BY 1
ORDER BY 1;

-- Paso 5: Verificar partition pruning
EXPLAIN SELECT * FROM ventas WHERE fecha = '2026-02-14';
EXPLAIN SELECT * FROM ventas WHERE region = 'norte';

-- Paso 6 (Reto): Tabla particionada por LIST (region) y tabla eventos por HASH
CREATE TABLE ventas_region (
    id bigint GENERATED ALWAYS AS IDENTITY,
    fecha date NOT NULL,
    region text NOT NULL,
    monto numeric(10,2),
    PRIMARY KEY (id, region)
) PARTITION BY LIST (region);

CREATE TABLE ventas_norte PARTITION OF ventas_region FOR VALUES IN ('norte');
CREATE TABLE ventas_sur PARTITION OF ventas_region FOR VALUES IN ('sur');
CREATE TABLE ventas_centro PARTITION OF ventas_region FOR VALUES IN ('centro');

INSERT INTO ventas_region (fecha, region, monto)
SELECT fecha, region, monto FROM ventas;

EXPLAIN SELECT * FROM ventas_region WHERE region = 'norte';

CREATE TABLE eventos (
    id bigint GENERATED ALWAYS AS IDENTITY,
    id_cliente int NOT NULL,
    tipo_evento text NOT NULL,
    fecha timestamp DEFAULT now(),
    PRIMARY KEY (id, id_cliente)
) PARTITION BY HASH (id_cliente);

CREATE TABLE eventos_h0 PARTITION OF eventos FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE eventos_h1 PARTITION OF eventos FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE eventos_h2 PARTITION OF eventos FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE eventos_h3 PARTITION OF eventos FOR VALUES WITH (MODULUS 4, REMAINDER 3);

INSERT INTO eventos (id_cliente, tipo_evento)
SELECT (random()*1000)::int, 'login' FROM generate_series(1, 4000);

SELECT tableoid::regclass, count(*) FROM eventos GROUP BY 1 ORDER BY 1;

-- Paso 7: Añadir una partición nueva (Opción A y Opción B) y cargar ventas_abril.csv
CREATE TABLE ventas_2026_04 PARTITION OF ventas
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE ventas_2026_05 (LIKE ventas INCLUDING ALL EXCLUDING IDENTITY);
ALTER TABLE ventas ATTACH PARTITION ventas_2026_05
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- Para cargar directamente sobre la partición hija sin pasar por la tabla padre,
-- vinculamos la secuencia de identidad de ventas.id como DEFAULT en la partición:
ALTER TABLE ventas_2026_04 ALTER COLUMN id SET DEFAULT nextval(pg_get_serial_sequence('ventas', 'id'));

\copy ventas_2026_04 (fecha, region, monto) FROM 'ventas_abril.csv' WITH (FORMAT csv, HEADER true)

SELECT count(*) FROM ventas_2026_04;

-- Paso 8: Eliminar y desvincular particiones
DROP TABLE ventas_2026_04;
ALTER TABLE ventas DETACH PARTITION ventas_2026_05;

-- Paso 9: Fusionar particiones de Q1 (enero, febrero, marzo)
ALTER TABLE ventas DETACH PARTITION ventas_2026_01;
ALTER TABLE ventas DETACH PARTITION ventas_2026_02;
ALTER TABLE ventas DETACH PARTITION ventas_2026_03;

CREATE TABLE ventas_2026_q1 (LIKE ventas INCLUDING ALL EXCLUDING IDENTITY);

INSERT INTO ventas_2026_q1 SELECT * FROM ventas_2026_01;
INSERT INTO ventas_2026_q1 SELECT * FROM ventas_2026_02;
INSERT INTO ventas_2026_q1 SELECT * FROM ventas_2026_03;

ALTER TABLE ventas ATTACH PARTITION ventas_2026_q1
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

SELECT tableoid::regclass, count(*) FROM ventas GROUP BY 1 ORDER BY 1;

DROP TABLE ventas_2026_01, ventas_2026_02, ventas_2026_03;
