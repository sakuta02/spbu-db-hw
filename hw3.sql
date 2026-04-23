-- Тема практики: Индексы + Группировки + Оконные функции

-- ЗАДАНИЕ 1 (GROUP BY + HAVING):
-- Найдите курсы, у которых доля сдавших (is_passed=true) < 60%.
-- Выведите: code, title, total, passed, passed_percent.
SELECT
    c.code,
    c.title,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE e.is_passed) AS passed,
    ROUND(100.0 * COUNT(*) FILTER (WHERE e.is_passed) / NULLIF(COUNT(*), 0), 2) AS passed_percent
FROM enrollments e
JOIN courses c ON c.course_id = e.course_id
GROUP BY c.code, c.title
HAVING 100.0 * COUNT(*) FILTER (WHERE e.is_passed) / NULLIF(COUNT(*), 0) < 60
ORDER BY passed_percent, total DESC, c.code;

-- ЗАДАНИЕ 2 (WINDOW):
-- Для каждого курса выведите:
--   semester, course_code, enrollments_count,
--   и место курса в семестре (RANK) по числу зачислений.
-- Подсказка: сначала GROUP BY semester, course_id, потом оконная.
WITH semester_course_counts AS (
    SELECT
        e.semester,
        e.course_id,
        COUNT(*) AS enrollments_count
    FROM enrollments e
    GROUP BY e.semester, e.course_id
)
SELECT
    scc.semester,
    c.code AS course_code,
    scc.enrollments_count,
    RANK() OVER (
        PARTITION BY scc.semester
        ORDER BY scc.enrollments_count DESC
    ) AS semester_rank
FROM semester_course_counts scc
JOIN courses c ON c.course_id = scc.course_id
ORDER BY scc.semester, semester_rank, c.code;

-- ЗАДАНИЕ 3 (WINDOW):
-- Выведите студентов, которые входят в TOP-3 по GPA внутри своей кафедры.
WITH ranked_students AS (
    SELECT
        s.student_id,
        s.first_name,
        s.last_name,
        s.major_department_id,
        s.gpa,
        DENSE_RANK() OVER (
            PARTITION BY s.major_department_id
            ORDER BY s.gpa DESC
        ) AS gpa_rank
    FROM students s
)
SELECT
    d.name AS department_name,
    rs.student_id,
    rs.first_name,
    rs.last_name,
    rs.gpa,
    rs.gpa_rank
FROM ranked_students rs
JOIN departments d ON d.department_id = rs.major_department_id
WHERE rs.gpa_rank <= 3
ORDER BY department_name, rs.gpa_rank, rs.student_id;

-- ЗАДАНИЕ 4 (INDEX DESIGN):
-- Придумайте индексы для запроса:
--   SELECT * FROM enrollments
--   WHERE semester='Fall 2023' AND is_passed=false
--   ORDER BY course_id;
-- Проверьте EXPLAIN (ANALYZE, BUFFERS) до и после.
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM enrollments
WHERE semester = 'Fall 2023'
  AND is_passed = FALSE
ORDER BY course_id;

CREATE INDEX IF NOT EXISTS enrollments_fall2023_failed_course_idx
ON enrollments (course_id)
WHERE semester = 'Fall 2023'
  AND is_passed = FALSE;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM enrollments
WHERE semester = 'Fall 2023'
  AND is_passed = FALSE
ORDER BY course_id;

DROP INDEX IF EXISTS enrollments_fall2023_failed_course_idx;

-- ЗАДАНИЕ 5 (EXPLAIN):
-- Возьмите любой ваш запрос с JOIN + GROUP BY и разберите план:
--   scan (Seq/Index/Bitmap), join (Nested/Hash/Merge), где узкое место.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    d.name AS department_name,
    COUNT(*) AS enrollments_count,
    ROUND(AVG(e.attendance_percent), 2) AS avg_attendance
FROM enrollments e
JOIN courses c ON c.course_id = e.course_id
JOIN departments d ON d.department_id = c.department_id
GROUP BY d.name
ORDER BY enrollments_count DESC;

-- Разбор плана:
-- 1) По таблице enrollments идёт Seq Scan.
--    Это нормально, потому что таблица маленькая и запросу всё равно нужны все строки.
-- 2) Основной join между enrollments и courses у меня получился через Hash Join.
--    Сначала PostgreSQL читает courses, строит hash, потом джоинит к enrollments.
-- 3) Для departments в плане был не отдельный Hash Join, а Nested Loop + Memoize + Index Scan.
--    То есть PostgreSQL запоминает уже найденные department_id и лишний раз их не читает.
-- 4) После join идёт HashAggregate по d.name, потом обычная сортировка по COUNT(*) DESC.
-- 5) Узкое место здесь не какое-то одно страшное место, а просто полный проход по enrollments.
--    Но на таком объёме данных это дешево, поэтому план в целом нормальный.
