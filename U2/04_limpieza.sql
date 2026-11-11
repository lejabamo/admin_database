-- ============================================================================
-- TALLER PRÁCTICO: COLLATION Y TABLESPACE EN POSTGRESQL (WINDOWS)
-- Sección 8: Limpieza del entorno
-- ============================================================================

\c postgres

ALTER USER postgres RESET default_tablespace;
ALTER DATABASE postgres RESET default_tablespace;

DROP DATABASE IF EXISTS pedidos_es;
DROP DATABASE IF EXISTS empresa_multinacional;

DROP TABLESPACE IF EXISTS ts_indices;
DROP TABLESPACE IF EXISTS ts_archivos;
DROP TABLESPACE IF EXISTS ts_hr;
DROP TABLESPACE IF EXISTS ts_finance;
DROP TABLESPACE IF EXISTS ts_sales;

SELECT spcname FROM pg_tablespace;
