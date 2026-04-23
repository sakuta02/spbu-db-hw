-- ЗАДАНИЕ 1 (CTE):
-- Найдите студентов, у которых средняя посещаемость >= 85 по всем курсам.
-- Выведите: student_id, ФИО, avg_attendance.
WITH attendance_stats AS (
    SELECT
        e.student_id,
        ROUND(AVG(e.attendance_percent), 2) AS avg_attendance
    FROM enrollments e
    GROUP BY e.student_id
)
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    a.avg_attendance
FROM attendance_stats a
JOIN students s ON s.student_id = a.student_id
WHERE a.avg_attendance >= 85
ORDER BY a.avg_attendance DESC, s.student_id
LIMIT 100;

-- ЗАДАНИЕ 2 (CTE + TOP-N):
-- Выведите TOP-3 кафедры по среднему GPA студентов (major_department),
WITH department_gpa AS (
    SELECT
        s.major_department_id,
        ROUND(AVG(s.gpa), 2) AS avg_gpa,
        COUNT(*) AS students_count
    FROM students s
    GROUP BY s.major_department_id
)
SELECT
    d.department_id,
    d.name AS department_name,
    dg.students_count,
    dg.avg_gpa
FROM department_gpa dg
JOIN departments d ON d.department_id = dg.major_department_id
ORDER BY dg.avg_gpa DESC, dg.students_count DESC, d.name
LIMIT 3;

-- ЗАДАНИЕ 3 (VIEW):
-- Создайте VIEW v_instructor_salary_level:
--   salary >= 100000 -> 'high'
--   salary >= 70000  -> 'mid'
--   иначе            -> 'low'
-- Затем посчитайте, сколько преподавателей в каждой категории.
CREATE OR REPLACE VIEW v_instructor_salary_level AS
SELECT
    instructor_id,
    first_name,
    last_name,
    salary,
    CASE
        WHEN salary >= 100000 THEN 'high'
        WHEN salary >= 70000  THEN 'mid'
        ELSE 'low'
    END AS salary_level
FROM instructors;

SELECT
    salary_level,
    COUNT(*) AS instructors_count
FROM v_instructor_salary_level
GROUP BY salary_level
ORDER BY instructors_count DESC, salary_level
LIMIT 100;

-- ЗАДАНИЕ 4 (TEMP):
-- Создайте TEMP таблицу tmp_failed_enrollments (is_passed = false).
-- Выведите: топ-10 курсов с максимальным числом провалов (id, число провалов).
DROP TABLE IF EXISTS tmp_failed_enrollments;
CREATE TEMP TABLE tmp_failed_enrollments AS
SELECT *
FROM enrollments
WHERE is_passed = FALSE;

SELECT
    course_id,
    COUNT(*) AS failed_count
FROM tmp_failed_enrollments
GROUP BY course_id
ORDER BY failed_count DESC, course_id
LIMIT 10;

-- ЗАДАНИЕ 5 (VIEW + CTE):
-- На основе v_student_course_enrollments найдите студентов, у которых >= 2 оценок 'F'.
-- Выведите student_id, ФИО, count_f.
CREATE OR REPLACE VIEW v_student_course_enrollments AS
SELECT
    e.enrollment_id,
    e.semester,
    e.grade,
    e.attendance_percent,
    e.is_passed,

    s.student_id,
    s.first_name AS student_first_name,
    s.last_name  AS student_last_name,
    s.enrollment_year,
    s.gpa,
    s.is_full_time,

    c.course_id,
    c.code AS course_code,
    c.title AS course_title,
    c.credits,
    c.level AS course_level,

    d.department_id AS course_department_id,
    d.name AS course_department_name
FROM enrollments e
JOIN students s  ON s.student_id = e.student_id
JOIN courses  c  ON c.course_id  = e.course_id
JOIN departments d ON d.department_id = c.department_id;

WITH failed_students AS (
    SELECT
        student_id,
        student_first_name,
        student_last_name,
        COUNT(*) AS count_f
    FROM v_student_course_enrollments
    WHERE grade = 'F'
    GROUP BY student_id, student_first_name, student_last_name
)
SELECT
    student_id,
    student_first_name,
    student_last_name,
    count_f
FROM failed_students
WHERE count_f >= 2
ORDER BY count_f DESC, student_id
LIMIT 100;
