-- Taller de optimización de consultas (u7 - univalle)
-- 03: Ejercicios 6 a 10 (Recursividad, Index Only Scan, Parciales y Subconsultas)

\c exercises

-- EJERCICIO 6: Consulta de Relaciones de Recomendación Recursiva
DROP INDEX IF EXISTS idx_bookings_starttime_date;
CREATE INDEX idx_bookings_facid_starttime ON bookings (facid, starttime);
CREATE INDEX idx_members_recommendedby ON members (recommendedby);
ANALYZE bookings;
ANALYZE members;

EXPLAIN (ANALYZE, BUFFERS)
WITH RECURSIVE recomendaciones AS (
    SELECT memid, firstname, surname, recommendedby, 1 as nivel
    FROM members
    WHERE memid = 13
    UNION ALL
    SELECT m.memid, m.firstname, m.surname, m.recommendedby, r.nivel + 1
    FROM members m
    INNER JOIN recomendaciones r ON m.recommendedby = r.memid
)
SELECT r.nivel,
       COUNT(DISTINCT r.memid) as miembros,
       COUNT(b.bookid) as total_reservas,
       SUM(b.slots) as total_slots
FROM recomendaciones r
JOIN bookings b ON r.memid = b.memid
JOIN facilities f ON b.facid = f.facid
WHERE b.facid IN (1, 3, 5)
  AND b.starttime >= '2025-06-01'
GROUP BY r.nivel
HAVING COUNT(b.bookid) > 0
ORDER BY r.nivel;

-- EJERCICIO 7: Análisis de Rentabilidad por Instalación (Index Only Scan)
DROP INDEX IF EXISTS idx_bookings_facid_starttime;
DROP INDEX IF EXISTS idx_members_recommendedby;

CREATE INDEX idx_bookings_covering_ej7 ON bookings (facid, starttime) INCLUDE (bookid, slots, memid);
VACUUM ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.name,
       f.initialoutlay,
       f.monthlymaintenance,
       COUNT(b.bookid) as reservas_mes,
       SUM(b.slots) as slots_mes,
       (SUM(CASE
            WHEN b.memid = 0 THEN f.guestcost * b.slots
            ELSE f.membercost * b.slots
        END) - f.monthlymaintenance) as ganancia_neta
FROM facilities f
JOIN bookings b ON f.facid = b.facid
WHERE b.starttime >= '2025-05-01' AND b.starttime < '2025-06-01'
  AND f.initialoutlay > 9000
GROUP BY f.facid, f.name, f.initialoutlay, f.monthlymaintenance
HAVING SUM(b.slots) > 20
ORDER BY ganancia_neta DESC;

-- EJERCICIO 8: Consulta de Miembros por Patrón de Uso
DROP INDEX IF EXISTS idx_bookings_covering_ej7;

CREATE INDEX idx_bookings_memid_starttime ON bookings (memid, starttime);
CREATE INDEX idx_members_joindate ON members (joindate);
ANALYZE bookings;
ANALYZE members;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.memid,
       m.firstname,
       m.surname,
       m.joindate,
       COUNT(DISTINCT b.facid) as instalaciones_utilizadas,
       COUNT(b.bookid) as total_reservas,
       SUM(b.slots) as total_slots,
       AVG(b.slots) as slots_promedio,
       MAX(b.starttime) as ultima_reserva
FROM members m
JOIN bookings b ON m.memid = b.memid
JOIN facilities f ON b.facid = f.facid
WHERE m.joindate > '2025-01-01'
  AND b.starttime > m.joindate
  AND f.membercost BETWEEN 0 AND 20
GROUP BY m.memid, m.firstname, m.surname, m.joindate
HAVING COUNT(b.bookid) >= 3
   AND COUNT(DISTINCT b.facid) > 1
ORDER BY total_slots DESC;

-- EJERCICIO 9: Análisis de Tendencia Mensual de Reservas Largas (Índice Parcial)
DROP INDEX IF EXISTS idx_bookings_memid_starttime;
DROP INDEX IF EXISTS idx_members_joindate;

CREATE INDEX idx_bookings_largas_partial ON bookings (starttime) WHERE slots >= 6;
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT EXTRACT(YEAR FROM b.starttime) as año,
       EXTRACT(MONTH FROM b.starttime) as mes,
       f.name,
       COUNT(b.bookid) as total_reservas,
       SUM(b.slots) as total_slots,
       AVG(b.slots) as slots_promedio,
       COUNT(DISTINCT b.memid) as miembros_unicos
FROM bookings b
JOIN facilities f ON b.facid = f.facid
WHERE b.slots >= 6
  AND b.starttime BETWEEN '2024-07-01' AND '2025-06-30'
GROUP BY EXTRACT(YEAR FROM b.starttime),
         EXTRACT(MONTH FROM b.starttime),
         f.name
HAVING COUNT(b.bookid) > 1
ORDER BY año, mes, total_slots DESC;

-- EJERCICIO 10: Consulta Compleja de Optimización de Espacios
DROP INDEX IF EXISTS idx_bookings_largas_partial;

CREATE INDEX idx_bookings_facid_starttime_slots ON bookings (facid, starttime) INCLUDE (slots, bookid);
VACUUM ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.facid,
       f.name,
       COUNT(b.bookid) as reservas_totales,
       SUM(b.slots) as slots_utilizados,
       30 * 25 as slots_disponibles,
       ROUND(SUM(b.slots) * 100.0 / (30 * 25), 2) as porcentaje_uso,
       (SELECT AVG(b2.slots)
        FROM bookings b2
        WHERE b2.facid = f.facid
          AND b2.starttime >= DATE '2025-06-01' - INTERVAL '3 months'
          AND b2.starttime <  DATE '2025-06-01') as slots_promedio_3meses
FROM facilities f
JOIN bookings b ON f.facid = b.facid
WHERE b.starttime >= DATE '2025-06-01'
  AND b.starttime <  DATE '2025-06-01' + INTERVAL '1 month'
  AND f.initialoutlay > 5000
GROUP BY f.facid, f.name
HAVING SUM(b.slots) > 50
ORDER BY porcentaje_uso DESC;

