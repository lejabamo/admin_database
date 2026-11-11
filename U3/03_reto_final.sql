-- Taller: particionamiento y carga de datos en postgresql 15+
-- Reto Final: Combinar particionamiento por LIST y carga masiva con COPY

\c taller_particiones
\timing on

DROP TABLE IF EXISTS pedidos;
CREATE TABLE pedidos (
    id bigint GENERATED ALWAYS AS IDENTITY,
    fecha date NOT NULL,
    region text NOT NULL,
    monto numeric(10,2),
    PRIMARY KEY (id, region)
) PARTITION BY LIST (region);

CREATE TABLE pedidos_norte PARTITION OF pedidos FOR VALUES IN ('norte');
CREATE TABLE pedidos_sur PARTITION OF pedidos FOR VALUES IN ('sur');
CREATE TABLE pedidos_centro PARTITION OF pedidos FOR VALUES IN ('centro');

\copy pedidos (fecha, region, monto) FROM 'pedidos_reto.csv' WITH (FORMAT csv, HEADER true)

SELECT tableoid::regclass AS particion, count(*) AS total_filas
FROM pedidos
GROUP BY 1
ORDER BY 1;

EXPLAIN SELECT * FROM pedidos WHERE region = 'sur';
