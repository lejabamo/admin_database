-- Taller práctico: backup y restore en postgresql (u6)
-- Paso 3: Simulación de pérdida de tabla (DROP TABLE ... CASCADE) y verificación

\c tienda

-- Antes del incidente: verificar conteo y llave foránea
SELECT count(*) AS total_clientes_antes FROM public.clientes;
SELECT conname, conrelid::regclass AS tabla, confrelid::regclass AS referencia
FROM pg_constraint
WHERE conrelid = 'ventas.pedidos'::regclass AND contype = 'f';

-- Simulamos el error humano: borrado accidental con CASCADE
DROP TABLE public.clientes CASCADE;

