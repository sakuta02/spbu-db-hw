------------------------------------------------------------
-- 6. Домашнее задание
------------------------------------------------------------

-- ЗАДАНИЕ 1.
-- Найти всех студентов, которые учатся на кафедре 'Computer Science'.
-- Подсказка: нужна связка students + departments.
SELECT *
FROM students
JOIN departments ON students.major_department_id = departments.department_id
WHERE departments.name = 'Computer Science';

-- ЗАДАНИЕ 2.
-- Вывести список курсов, которые принадлежат кафедре 'Mathematics',
-- только поле code и title, отсортировать по code.
SELECT code, title
FROM courses
JOIN departments on departments.department_id = courses.department_id
WHERE departments.name = 'Mathematics'
ORDER BY code;

-- ЗАДАНИЕ 3.
-- Вывести студентов, у которых GPA < 2.5, отсортировать по GPA по возрастанию.
SELECT *
FROM students
WHERE gpa < 2.5
ORDER BY gpa;

-- ЗАДАНИЕ 4.
-- Сделать запрос, который покажет:
--   имя студента, фамилию, семестр и код курса,
--   только для зачислений, где есть оценка (grade не пустой).
SELECT first_name, last_name, semester, course_id
FROM students
JOIN enrollments ON students.student_id = enrollments.student_id
WHERE enrollments.grade IS NOT NULL;

-- ЗАДАНИЕ 5.
-- Вывести 10 студентов с самым высоким GPA (TOP-10).
SELECT *
FROM students
ORDER BY gpa DESC
LIMIT 10;

