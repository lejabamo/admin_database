-- ============================================================================
-- TALLER DE OPTIMIZACIÓN DE CONSULTAS (U7 - UNIVALLE)
-- 01: Preparación del Entorno y Bloque de Limpieza de Índices Secundarios
-- ============================================================================

-- 1. Crear base de datos exercises y actualizar estadísticas tras restaurar el dump
-- CREATE DATABASE exercises;
\c exercises
VACUUM ANALYZE;

-- Verificar páginas y tuplas de las tablas del club
SELECT relname AS tabla, relpages AS paginas, reltuples::bigint AS filas_estimadas
FROM pg_class
WHERE relname IN ('bookings', 'facilities', 'members')
ORDER BY relname;

-- 2. Procedimiento base para eliminar todos los índices que no sean llave primaria
--    antes de medir el plan base de cada ejercicio:
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT indexname FROM pg_indexes
           WHERE schemaname = 'public' AND indexname NOT LIKE '%_pk'
  LOOP
    EXECUTE 'DROP INDEX public.' || quote_ident(r.indexname);
  END LOOP;
END $$;
VACUUM ANALYZE;
