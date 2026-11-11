-- Taller: particionamiento y carga de datos en postgresql 15+
-- Parte 2: INSERT fila a fila vs. en lotes vs. COPY (Pasos 10 a 13)

\c taller_particiones
\timing on

-- Paso 10: Insertar 2000 filas una por una dentro de un bucle DO
DO $$
BEGIN
  FOR i IN 1..2000 LOOP
    INSERT INTO ventas (fecha, region, monto)
    VALUES (date '2026-01-01' + (i % 90), 'centro', 10.00);
  END LOOP;
END $$;

-- Paso 11: Insertar 2000 filas en una sola sentencia con generate_series
INSERT INTO ventas (fecha, region, monto)
SELECT date '2026-01-01' + (i % 90), 'centro', 10.00
FROM generate_series(1, 2000) AS i;

-- Inserción multivalor literal
INSERT INTO ventas (fecha, region, monto) VALUES
  ('2026-01-05', 'sur', 45.20),
  ('2026-01-06', 'sur', 12.75),
  ('2026-01-07', 'sur', 98.00);

-- Paso 12: Exportar e importar con \copy sobre la tabla padre ventas
\copy (SELECT fecha, region, monto FROM ventas WHERE fecha >= '2026-03-01' AND fecha < '2026-04-01' LIMIT 3000) TO 'ventas_marzo_export.csv' WITH (FORMAT csv, HEADER true)

\copy ventas (fecha, region, monto) FROM 'ventas_marzo.csv' WITH (FORMAT csv, HEADER true)

-- Paso 13: Cargar directo en una partición mensual (recreando ventas_2026_03 para la prueba)
ALTER TABLE ventas DETACH PARTITION ventas_2026_q1;
CREATE TABLE ventas_2026_01 PARTITION OF ventas FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE ventas_2026_02 PARTITION OF ventas FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE ventas_2026_03 PARTITION OF ventas FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
ALTER TABLE ventas_2026_03 ALTER COLUMN id SET DEFAULT nextval(pg_get_serial_sequence('ventas', 'id'));

\copy ventas_2026_03 (fecha, region, monto) FROM 'ventas_marzo.csv' WITH (FORMAT csv, HEADER true)

SELECT count(*) FROM ventas_2026_03;
