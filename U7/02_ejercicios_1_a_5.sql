-- ============================================================================
-- TALLER DE OPTIMIZACIÓN DE CONSULTAS (U7 - UNIVALLE)
-- 02: Ejercicios 1 a 5 (Comparación EXPLAIN ANALYZE BUFFERS Antes y Después)
-- ============================================================================

\c exercises

-- ============================================================================
-- EJERCICIO 1: Consulta de Reservas por Rango de Fechas con Agregaciones
-- ============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT f.name,
       COUNT(b.bookid) as total_reservas,
       SUM(b.slots) as total_slots,
       AVG(b.slots) as promedio_slots
FROM bookings b
JOIN facilities f ON b.facid = f.facid
WHERE b.starttime BETWEEN '2025-03-03' AND '2025-03-09 23:59:59'
  AND b.slots > 2
GROUP BY f.facid, f.name
HAVING COUNT(b.bookid) > 3
ORDER BY total_reservas DESC;

CREATE INDEX idx_bookings_starttime_slots ON bookings (starttime, slots);
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.name,
       COUNT(b.bookid) as total_reservas,
       SUM(b.slots) as total_slots,
       AVG(b.slots) as promedio_slots
FROM bookings b
JOIN facilities f ON b.facid = f.facid
WHERE b.starttime BETWEEN '2025-03-03' AND '2025-03-09 23:59:59'
  AND b.slots > 2
GROUP BY f.facid, f.name
HAVING COUNT(b.bookid) > 3
ORDER BY total_reservas DESC;

-- ============================================================================
-- EJERCICIO 2: Búsqueda de Miembros con Patrones de Texto y Recomendaciones
-- ============================================================================
DROP INDEX IF EXISTS idx_bookings_starttime_slots;
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m1.memid,
       m1.firstname,
       m1.surname,
       m2.firstname as recomendador_nombre,
       m2.surname as recomendador_apellido,
       COUNT(b.bookid) as total_reservas
FROM members m1
LEFT JOIN members m2 ON m1.recommendedby = m2.memid
LEFT JOIN bookings b ON m1.memid = b.memid
WHERE (m1.surname LIKE 'Smith%' OR m1.firstname LIKE 'J%')
  AND m1.joindate > '2024-01-01'
GROUP BY m1.memid, m1.firstname, m1.surname, m2.firstname, m2.surname
ORDER BY total_reservas DESC;

CREATE INDEX idx_bookings_memid ON bookings (memid);
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m1.memid,
       m1.firstname,
       m1.surname,
       m2.firstname as recomendador_nombre,
       m2.surname as recomendador_apellido,
       COUNT(b.bookid) as total_reservas
FROM members m1
LEFT JOIN members m2 ON m1.recommendedby = m2.memid
LEFT JOIN bookings b ON m1.memid = b.memid
WHERE (m1.surname LIKE 'Smith%' OR m1.firstname LIKE 'J%')
  AND m1.joindate > '2024-01-01'
GROUP BY m1.memid, m1.firstname, m1.surname, m2.firstname, m2.surname
ORDER BY total_reservas DESC;

-- ============================================================================
-- EJERCICIO 3: Análisis de Costos vs Utilización
-- ============================================================================
DROP INDEX IF EXISTS idx_bookings_memid;
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.facid,
       f.name,
       f.membercost,
       f.guestcost,
       COUNT(b.bookid) as num_reservas,
       SUM(CASE
           WHEN b.memid = 0 THEN f.guestcost * b.slots
           ELSE f.membercost * b.slots
       END) as ingresos_estimados
FROM facilities f
JOIN bookings b ON f.facid = b.facid
WHERE b.facid IN (4, 5)
  AND b.starttime >= DATE '2025-06-30' - INTERVAL '1 month'
GROUP BY f.facid, f.name, f.membercost, f.guestcost
HAVING SUM(b.slots) > 10
ORDER BY ingresos_estimados DESC;

CREATE INDEX idx_bookings_facid_starttime ON bookings (facid, starttime);
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT f.facid,
       f.name,
       f.membercost,
       f.guestcost,
       COUNT(b.bookid) as num_reservas,
       SUM(CASE
           WHEN b.memid = 0 THEN f.guestcost * b.slots
           ELSE f.membercost * b.slots
       END) as ingresos_estimados
FROM facilities f
JOIN bookings b ON f.facid = b.facid
WHERE b.facid IN (4, 5)
  AND b.starttime >= DATE '2025-06-30' - INTERVAL '1 month'
GROUP BY f.facid, f.name, f.membercost, f.guestcost
HAVING SUM(b.slots) > 10
ORDER BY ingresos_estimados DESC;

-- ============================================================================
-- EJERCICIO 4: Consulta de Miembros Activos por Zona Geográfica
-- ============================================================================
DROP INDEX IF EXISTS idx_bookings_facid_starttime;
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.zipcode,
       COUNT(DISTINCT m.memid) as total_miembros,
       COUNT(b.bookid) as total_reservas,
       AVG(b.slots) as slots_promedio
FROM members m
JOIN bookings b ON m.memid = b.memid
JOIN facilities f ON b.facid = f.facid
WHERE m.joindate BETWEEN '2024-01-01' AND '2024-12-31'
  AND b.starttime BETWEEN '2025-03-01' AND '2025-03-31'
  AND f.membercost >= 5
GROUP BY m.zipcode
HAVING COUNT(b.bookid) > 1
ORDER BY total_reservas DESC;

CREATE INDEX idx_bookings_starttime_memid ON bookings (starttime, memid);
CREATE INDEX idx_members_joindate ON members (joindate);
ANALYZE bookings;
ANALYZE members;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.zipcode,
       COUNT(DISTINCT m.memid) as total_miembros,
       COUNT(b.bookid) as total_reservas,
       AVG(b.slots) as slots_promedio
FROM members m
JOIN bookings b ON m.memid = b.memid
JOIN facilities f ON b.facid = f.facid
WHERE m.joindate BETWEEN '2024-01-01' AND '2024-12-31'
  AND b.starttime BETWEEN '2025-03-01' AND '2025-03-31'
  AND f.membercost >= 5
GROUP BY m.zipcode
HAVING COUNT(b.bookid) > 1
ORDER BY total_reservas DESC;

-- ============================================================================
-- EJERCICIO 5: Análisis Temporal de Horarios Pico
-- ============================================================================
DROP INDEX IF EXISTS idx_bookings_starttime_memid;
DROP INDEX IF EXISTS idx_members_joindate;
ANALYZE bookings;

-- Solución A: Índice funcional sobre la expresión CAST(starttime AS DATE)
CREATE INDEX idx_bookings_starttime_date ON bookings (CAST(starttime AS DATE));
ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT EXTRACT(HOUR FROM b.starttime) as hora,
       EXTRACT(DOW FROM b.starttime) as dia_semana,
       f.name,
       COUNT(b.bookid) as reservas,
       SUM(b.slots) as slots_totales,
       AVG(b.slots) as slots_promedio
FROM bookings b
JOIN facilities f ON b.facid = f.facid
WHERE CAST(b.starttime AS DATE) BETWEEN '2025-05-12' AND '2025-05-18'
  AND f.membercost <= 10
GROUP BY EXTRACT(HOUR FROM b.starttime),
         EXTRACT(DOW FROM b.starttime),
         f.name
HAVING COUNT(b.bookid) > 1
ORDER BY slots_totales DESC;
