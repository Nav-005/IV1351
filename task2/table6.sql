

-- Total allocated hours per teacher for current year's course instances
SELECT
    cl.course_code,
    ci.instance_id AS "Course Instance ID",
    cl.hp AS "HP",
    ci.study_period AS "Period",
    p.first_name || ' ' || p.last_name AS "Teacher's Name",

    -- Allocated hours per activity type multiplied by factor
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Lecture' THEN a.allocated_hours * ta.factor END),0) AS "Lecture Hours",
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Tutorial' THEN a.allocated_hours * ta.factor END),0) AS "Tutorial Hours",
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Lab' THEN a.allocated_hours * ta.factor END),0) AS "Lab Hours",
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Seminar' THEN a.allocated_hours * ta.factor END),0) AS "Seminar Hours",

    -- Other Overhead = allocated hours for activities NOT in Lecture, Tutorial, Lab, Seminar
    COALESCE(SUM(CASE WHEN ta.activity_name NOT IN ('Lecture','Tutorial','Lab','Seminar') THEN a.allocated_hours * ta.factor END),0) AS "Other Overhead Hours",

    ci.admin_hours AS "Admin",
    ci.exam_hours AS "Exam",

    -- Total = sum of all activity hours + admin + exam
    COALESCE(SUM(a.allocated_hours * ta.factor),0) + ci.admin_hours + ci.exam_hours AS "Total"

FROM allocation a
JOIN planned_activity pa ON a.planned_activity_id = pa.planned_activity_id
JOIN course_instance ci ON pa.instance_id = ci.instance_id
JOIN course_layout cl ON ci.course_id = cl.course_id
JOIN teaching_activity ta ON pa.activity_type_id = ta.activity_type_id
JOIN employee e ON a.employee_id = e.employee_id
JOIN person p ON e.person_id = p.person_id

WHERE ci.study_year = 2023
-- Optional filter for a specific teacher:
AND p.first_name || ' ' || p.last_name = 'Alice Brown'

GROUP BY cl.course_code, ci.instance_id, cl.hp, ci.study_period, p.first_name, p.last_name, ci.admin_hours, ci.exam_hours
ORDER BY p.first_name, p.last_name, ci.study_period, cl.course_code;

