-- ============================================================================
-- TALLER PRÁCTICO: GESTIÓN DE USUARIOS, ROLES Y PERMISOS EN POSTGRESQL
-- Sección 9: Script de Limpieza
-- ============================================================================

\c postgres

DROP DATABASE IF EXISTS empresa_db WITH (FORCE);

DROP ROLE IF EXISTS usr_web_backend, usr_web_cliente, usr_web_root;
DROP ROLE IF EXISTS web_app, web_user, web_admin;
DROP ROLE IF EXISTS carlos, maria, pedro, ana;
DROP ROLE IF EXISTS gerentes, desarrolladores, analistas, lectores;
DROP ROLE IF EXISTS usuario_app, admin_bd, desarrollador, desarrollador_senior;
DROP ROLE IF EXISTS grupo_desarrolladores, grupo_lectores;
