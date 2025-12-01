--QUERY 1: Planned hours calculations:
SELECT 
    cl.course_code,
    ci.instance_id AS "Course Instance ID",
    cl.hp AS "HP",
    ci.study_period AS "Period",
    ci.num_students AS "# Students",

    COALESCE(SUM(CASE WHEN ta.activity_name = 'Lecture' THEN pa.planned_hours * ta.factor END),0) AS "Lecture Hours",
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Tutorial' THEN pa.planned_hours * ta.factor END),0) AS "Tutorial Hours",
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Lab' THEN pa.planned_hours * ta.factor END),0) AS "Lab Hours",
    COALESCE(SUM(CASE WHEN ta.activity_name = 'Seminar' THEN pa.planned_hours * ta.factor END),0) AS "Seminar Hours",

    -- Other Overhead = All hours - Lecture - Tutorial - Lab - Seminar
    COALESCE(SUM(pa.planned_hours * ta.factor),0)
        - COALESCE(SUM(CASE WHEN ta.activity_name IN ('Lecture','Tutorial','Lab','Seminar') 
                             THEN pa.planned_hours * ta.factor END),0)
        AS "Other Overhead Hours",

    ci.admin_hours AS "Admin",
    ci.exam_hours AS "Exam",
    COALESCE(SUM(pa.planned_hours * ta.factor),0) + ci.admin_hours + ci.exam_hours AS "Total Hours"

FROM course_instance ci
JOIN course_layout cl ON ci.course_id = cl.course_id
LEFT JOIN planned_activity pa ON ci.instance_id = pa.instance_id
LEFT JOIN teaching_activity ta ON pa.activity_type_id = ta.activity_type_id
WHERE ci.study_year = 2023
GROUP BY cl.course_code, ci.instance_id, cl.hp, ci.study_period, ci.num_students, ci.admin_hours, ci.exam_hours
ORDER BY cl.course_code, ci.instance_id;

