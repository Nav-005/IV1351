-- DROP TABLES in reverse dependency order
DROP TABLE IF EXISTS allocation CASCADE;
DROP TABLE IF EXISTS planned_activity CASCADE;
DROP TABLE IF EXISTS employee_skill CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS course_instance CASCADE;
DROP TABLE IF EXISTS teaching_activity CASCADE;
DROP TABLE IF EXISTS phone_number CASCADE;
DROP TABLE IF EXISTS person CASCADE;
DROP TABLE IF EXISTS job_title CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS course_layout CASCADE;
DROP TABLE IF EXISTS skill CASCADE;

-- COURSE LAYOUT
CREATE TABLE course_layout (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(500),
    min_students INT,
    max_students INT,
    hp DECIMAL(10),
    layout_version DECIMAL(10),
    valid_from DATE,
    course_code CHAR(10)
);

-- DEPARTMENT
CREATE TABLE department (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(200) UNIQUE,
    manager_id INT NOT NULL
);

-- JOB TITLE
CREATE TABLE job_title (
    job_title_id SERIAL PRIMARY KEY,
    jobtitle VARCHAR(200)
);

-- PERSON
CREATE TABLE person (
    person_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20),
    last_name VARCHAR(10),
    address VARCHAR(100),
    personal_number VARCHAR(13)
);

-- PHONE NUMBER
CREATE TABLE phone_number (
    phone_number VARCHAR(10) NOT NULL,
    person_id INT NOT NULL,
    PRIMARY KEY (phone_number, person_id),
    CONSTRAINT FK_phone_number_0 FOREIGN KEY (person_id) REFERENCES person(person_id) ON DELETE CASCADE
);

-- SKILL
CREATE TABLE skill (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(500)
);

-- TEACHING ACTIVITY
CREATE TABLE teaching_activity (
    activity_type_id SERIAL PRIMARY KEY,
    activity_name VARCHAR(100) UNIQUE,
    factor DECIMAL(10,2)
);

-- COURSE INSTANCE
CREATE TABLE course_instance (
    instance_id SERIAL PRIMARY KEY,
    num_students INT,
    study_period CHAR(2),
    study_year INT,
    admin_hours DECIMAL(10,2),
    exam_hours DECIMAL(10,2),
    course_id INT NOT NULL,
    CONSTRAINT FK_course_instance_0 FOREIGN KEY (course_id) REFERENCES course_layout(course_id) ON DELETE RESTRICT
);

-- EMPLOYEE
CREATE TABLE employee (
    employee_id SERIAL PRIMARY KEY,
    salary INT,
    manager_id INT NOT NULL,
    job_title_id INT NOT NULL,
    skill_set VARCHAR(500) NOT NULL,
    person_id INT NOT NULL,
    department_id INT NOT NULL,
    CONSTRAINT FK_employee_0 FOREIGN KEY (job_title_id) REFERENCES job_title(job_title_id) ON DELETE RESTRICT,
    CONSTRAINT FK_employee_1 FOREIGN KEY (person_id) REFERENCES person(person_id) ON DELETE RESTRICT,
    CONSTRAINT FK_employee_2 FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE RESTRICT
);

-- EMPLOYEE_SKILL
CREATE TABLE employee_skill (
    skill_id INT NOT NULL,
    employee_id INT NOT NULL,
    CONSTRAINT PK_employee_skill PRIMARY KEY (skill_id, employee_id),
    CONSTRAINT FK_employee_skill_0 FOREIGN KEY (skill_id) REFERENCES skill(skill_id) ON DELETE RESTRICT,
    CONSTRAINT FK_employee_skill_1 FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE RESTRICT
);

-- PLANNED ACTIVITY
CREATE TABLE planned_activity (
    planned_activity_id SERIAL PRIMARY KEY,
    planned_hours DECIMAL(10,2),
    activity_type_id INT NOT NULL,
    employee_id INT NOT NULL,
    instance_id INT NOT NULL,
    CONSTRAINT FK_planned_activity_0 FOREIGN KEY (activity_type_id) REFERENCES teaching_activity(activity_type_id) ON DELETE RESTRICT,
    CONSTRAINT FK_planned_activity_1 FOREIGN KEY (instance_id) REFERENCES course_instance(instance_id) ON DELETE RESTRICT
);

-- ALLOCATION
CREATE TABLE allocation (
    planned_activity_id INT NOT NULL,
    employee_id INT NOT NULL,
    allocated_hours DECIMAL(10,2),
    CONSTRAINT PK_allocation PRIMARY KEY (planned_activity_id, employee_id),
    CONSTRAINT FK_allocation_0 FOREIGN KEY (planned_activity_id) REFERENCES planned_activity(planned_activity_id) ON DELETE RESTRICT,
    CONSTRAINT FK_allocation_1 FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE RESTRICT
);

-- Trigger to limit max 4 course instances per employee per study period
CREATE OR REPLACE FUNCTION check_teacher_allocation()
RETURNS TRIGGER AS $$
DECLARE
    current_period CHAR(2);
    allocation_count INT;
BEGIN
    SELECT ci.study_period INTO current_period
    FROM planned_activity pa
    JOIN course_instance ci ON pa.instance_id = ci.instance_id
    WHERE pa.planned_activity_id = NEW.planned_activity_id;

    SELECT COUNT(DISTINCT pa.instance_id) INTO allocation_count
    FROM allocation a
    JOIN planned_activity pa ON a.planned_activity_id = pa.planned_activity_id
    JOIN course_instance ci ON pa.instance_id = ci.instance_id
    WHERE a.employee_id = NEW.employee_id
      AND ci.study_period = current_period;

    IF allocation_count >= 4 THEN
        RAISE EXCEPTION 'Employee % is already allocated to 4 course instances in period %', NEW.employee_id, current_period;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_teacher_allocation
BEFORE INSERT OR UPDATE ON allocation
FOR EACH ROW
EXECUTE FUNCTION check_teacher_allocation();

-- INSERT DATA

-- PERSONS
INSERT INTO person (first_name, last_name, address, personal_number) VALUES
('John','Doe','123 Gamla stan','19900101-1234'),
('Jane','Smith','456 Hornstull','19920202-2345'),
('Alice','Brown','789 Jakobsberg','19880505-3456'),
('Bob','Johnson','101 Hornstull','19930303-4567'),
('Eve','Davis','202 Kalmgata','19950505-5678'),
('Charlie','Miller','303 Centralgata','19960606-6789'),
('Grace','Wilson','404 Brygggata','19970707-7890'),
('Oscar','Moore','505 Halpersgata','19980808-8901'),
('Mia','Taylor','606 Jijigata','19990909-9012'),
('Leo','Anderson','707 Najs Gata','20000101-0123');

-- PHONE NUMBERS
INSERT INTO phone_number (phone_number, person_id) VALUES
('0701234567',1),('0702345678',2),('0703456789',3),('0704567890',4),('0705678901',5),
('0706789012',6),('0707890123',7),('0708901234',8),('0709012345',9),('0700123456',10);

-- DEPARTMENTS
INSERT INTO department (department_name, manager_id) VALUES
('Mathematics',1),('Physics',2),('Chemistry',3),('Biology',4),('English',5),
('History',6),('Computer Science',7),('Art',8),('Music',9),('Philosophy',10);

-- JOB TITLES
INSERT INTO job_title (jobtitle) VALUES
('Professor'),('Lecturer'),('AsstProf'),('LabAsst'),('Researcher'),
('Tutor'),('Admin'),('Ordinator'),('Manager'),('HR');

-- EMPLOYEES
INSERT INTO employee (salary, manager_id, job_title_id, skill_set, person_id, department_id) VALUES
(50000,1,1,'Math, Algebra, Geometry, Analysis, Teaching',1,1),
(45000,1,2,'Physics, Mechanics, Thermodynamics, Research, Lab',2,2),
(40000,2,3,'Chemistry, Lab, Organic, Inorganic, Safety',3,3),
(42000,2,4,'Biology, Genetics, Experiments, Ecology, Teaching',4,4),
(47000,3,5,'English, Writing, Communication, Literature, Teaching',5,5),
(48000,3,6,'History, Research, Events, Analysis, Tutoring',6,6),
(55000,4,7,'CS, Programming, Algorithms, AI, Databases',7,7),
(43000,4,8,'Art, Painting, Design, Sculpture, Creativity',8,8),
(41000,5,9,'Music, Instruments, Theory, Composition, Performance',9,9),
(46000,5,10,'Philosophy, Logic, Ethics, Analysis, Writing',10,10);

-- SKILLS
INSERT INTO skill (skill_name) VALUES
('Math'),('Physics'),('Chemistry'),('Biology'),('English'),
('History'),('CS'),('Art'),('Music'),('Philosophy');

-- EMPLOYEE_SKILLS
INSERT INTO employee_skill (skill_id, employee_id) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),
(2,1),(2,2),(2,3),(2,4),(2,5),
(3,6),(4,7),(5,8),(6,9),(7,10),
(8,1),(9,2),(10,3);

-- COURSE LAYOUTS
INSERT INTO course_layout (course_name, min_students, max_students, hp, layout_version, valid_from, course_code) VALUES
('Math',5,30,7.5,1.0,'2023-08-01','MATH101'),
('Physics',5,40,7.5,1.0,'2023-08-01','PHYS101'),
('Chemistry',5,35,7.5,1.0,'2023-08-01','CHEM101'),
('Biology',5,30,7.5,1.0,'2023-08-01','BIOL101'),
('English',5,50,5.0,1.0,'2023-08-01','ENG101'),
('History',5,40,5.0,1.0,'2023-08-01','HIST101'),
('CS',5,50,10.0,1.0,'2023-08-01','CS101'),
('Art',5,25,5.0,1.0,'2023-08-01','ART101'),
('Music',3,20,5.0,1.0,'2023-08-01','MUS101'),
('Philosophy',5,30,5.0,1.0,'2023-08-01','PHIL101');

-- TEACHING ACTIVITIES
INSERT INTO teaching_activity (activity_name, factor) VALUES
('Lecture',3.6),('Lab',2.4),('Tutorial',2.4),('Seminar',1.8),('Workshop',2.0),
('Project',2.5),('Discussion',1.5),('Presentation',1.2),('Exercise',2.0),('Fieldwork',2.3);

-- COURSE INSTANCES
INSERT INTO course_instance (num_students, study_period, study_year, admin_hours, exam_hours, course_id) VALUES
(25,'P1',2023,10.0,5.0,1),(30,'P1',2023,12.0,6.0,2),(20,'P2',2023,8.0,4.0,3),
(15,'P2',2023,9.0,4.5,4),(40,'P1',2023,11.0,5.5,5),(35,'P2',2023,10.0,5.0,6),
(50,'P3',2023,15.0,7.0,7),(20,'P4',2023,7.0,3.5,8),(10,'P3',2023,6.0,2.5,9),
(30,'P4',2023,9.0,4.0,10);

-- PLANNED ACTIVITIES
-- PLANNED ACTIVITIES: Each course instance has multiple types of activities
-- Format: (planned_hours, activity_type_id, employee_id, instance_id)

-- activity_type_id mapping:
-- 1 = Lecture, 2 = Lab, 3 = Tutorial, 4 = Seminar, 5 = Workshop, 6 = Project, 7 = Discussion, 8 = Presentation, 9 = Exercise, 10 = Fieldwork

-- Course instance 1: MATH101
INSERT INTO planned_activity (planned_hours, activity_type_id, employee_id, instance_id) VALUES
(10,1,1,1),  -- Lecture
(6,3,1,1),   -- Tutorial
(4,2,1,1),   -- Lab
(2,4,1,1),   -- Seminar
(3,5,1,1),
(8,1,2,2),
(5,3,2,2),
(6,2,2,2),
(3,4,2,2),
(2,6,2,2),
(7,1,3,3),
(4,3,3,3),
(8,2,3,3),
(2,4,3,3),
(3,7,3,3),
(5,1,4,4),
(3,3,4,4),
(4,2,4,4),
(2,4,4,4),
(1,8,4,4),
(6,1,5,5),
(4,3,5,5),
(0,2,5,5),  -- No Lab
(2,4,5,5),
(3,5,5,5),
(5,1,6,6),
(3,3,6,6),
(0,2,6,6),  -- No Lab
(2,4,6,6),
(2,6,6,6),
(9,1,7,7),
(6,3,7,7),
(8,2,7,7),
(4,4,7,7),
(5,5,7,7),
(4,1,8,8),
(0,3,8,8),  -- No Tutorial
(0,2,8,8),  -- No Lab
(3,4,8,8),
(4,8,8,8),
(3,1,9,9),
(2,3,9,9),
(0,2,9,9),
(1,4,9,9),
(2,5,9,9),
(4,1,10,10),
(3,3,10,10),
(0,2,10,10),
(1,4,10,10),
(2,7,10,10);

-- ALLOCATIONS
-- ALLOCATIONS: Assign every planned activity to a teacher with allocated hours
INSERT INTO allocation (planned_activity_id, employee_id, allocated_hours) VALUES
-- MATH101 (instance_id=1)
(1,1,10),(2,3,6),(3,1,4),(4,2,2),(5,3,3),

-- PHYS101 (instance_id=2)
(6,2,8),(7,2,5),(8,2,6),(9,2,3),(10,2,2),

-- CHEM101 (instance_id=3)
(11,3,7),(12,3,4),(13,3,8),(14,3,2),(15,3,3),

-- BIOL101 (instance_id=4)
(16,4,5),(17,4,3),(18,4,4),(19,4,2),(20,4,1),

-- ENG101 (instance_id=5)
(21,5,6),(22,5,4),(23,5,0),(24,5,2),(25,5,3),

-- HIST101 (instance_id=6)
(26,6,5),(27,6,3),(28,6,0),(29,6,2),(30,6,2),

-- CS101 (instance_id=7)
(31,7,9),(32,7,6),(33,7,8),(34,7,4),(35,7,5),

-- ART101 (instance_id=8)
(36,8,4),(37,8,0),(38,8,0),(39,8,3),(40,8,4),

-- MUS101 (instance_id=9)
(41,9,3),(42,9,2),(43,9,0),(44,9,1),(45,9,2),

-- PHIL101 (instance_id=10)
(46,10,4),(47,10,3),(48,10,0),(49,10,1),(50,10,2);



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


--QUERY 2: Actual allocated hours for a course:
SELECT
    cl.course_code,
    ci.instance_id AS "Course Instance ID",
    cl.hp AS "HP",
    p.first_name || ' ' || p.last_name AS "Teacher's Name",
    jt.jobtitle AS "Designation",

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
JOIN job_title jt ON e.job_title_id = jt.job_title_id
JOIN person p ON e.person_id = p.person_id

WHERE ci.study_year = 2023
	 AND ci.course_id = 1

GROUP BY cl.course_code, ci.instance_id, cl.hp, p.first_name, p.last_name, jt.jobtitle, ci.admin_hours, ci.exam_hours

ORDER BY cl.course_code, ci.instance_id, "Teacher's Name";


