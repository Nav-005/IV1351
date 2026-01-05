-- ============================================================
-- DROP TABLES IN REVERSE ORDER TO AVOID FK ERRORS
-- ============================================================
DROP TABLE IF EXISTS allocation CASCADE;
DROP TABLE IF EXISTS planned_activity CASCADE;
DROP TABLE IF EXISTS employee_skill CASCADE;
DROP TABLE IF EXISTS employee_salary CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS job_title CASCADE;
DROP TABLE IF EXISTS phone_number CASCADE;
DROP TABLE IF EXISTS person CASCADE;
DROP TABLE IF EXISTS course_instance CASCADE;
DROP TABLE IF EXISTS course_layout_version CASCADE;
DROP TABLE IF EXISTS course CASCADE;
DROP TABLE IF EXISTS teaching_activity CASCADE;
DROP TABLE IF EXISTS skill CASCADE;
DROP TABLE IF EXISTS system_rules CASCADE;

-- ============================================================
-- CORE ENTITIES
-- ============================================================

CREATE TABLE course (
    course_id INT PRIMARY KEY,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    course_name VARCHAR(500) NOT NULL
);

CREATE TABLE course_layout_version (
    layout_version_id INT PRIMARY KEY,
    course_id INT NOT NULL,
    layout_version VARCHAR(10) NOT NULL,
    min_students INT NOT NULL,
    max_students INT NOT NULL,
    hp DECIMAL(4,1) NOT NULL,
    valid_from DATE NOT NULL,
    CONSTRAINT FK_clv_course FOREIGN KEY (course_id) REFERENCES course(course_id),
    CONSTRAINT U_course_version UNIQUE (course_id, layout_version)
);

CREATE TABLE course_instance (
    instance_id INT PRIMARY KEY,
    layout_version_id INT NOT NULL,
    num_students INT NOT NULL,
    study_period VARCHAR(10) NOT NULL,
    study_year INT NOT NULL,
    admin_hours DECIMAL(5,2),
    exam_hours DECIMAL(5,2),
    CONSTRAINT FK_instance_layout FOREIGN KEY (layout_version_id) REFERENCES course_layout_version(layout_version_id)
);

-- ============================================================
-- PEOPLE, JOBS, SKILLS
-- ============================================================

CREATE TABLE person (
    person_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    address VARCHAR(100),
    personal_number VARCHAR(13)
);

CREATE TABLE phone_number (
    phone_number VARCHAR(15),
    person_id INT,
    PRIMARY KEY (phone_number, person_id),
    CONSTRAINT FK_phone_person FOREIGN KEY (person_id) REFERENCES person(person_id)
);

CREATE TABLE job_title (
    job_title_id INT PRIMARY KEY,
    jobtitle VARCHAR(50) NOT NULL
);

-- Create department without FK first (to handle circular dependency)
CREATE TABLE department (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(200) NOT NULL UNIQUE,
    manager_id INT  -- FK will be added later
);

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    person_id INT NOT NULL,
    job_title_id INT NOT NULL,
    department_id INT NOT NULL,
    manager_id INT, -- FK will be added later
    CONSTRAINT FK_emp_person FOREIGN KEY (person_id) REFERENCES person(person_id),
    CONSTRAINT FK_emp_job FOREIGN KEY (job_title_id) REFERENCES job_title(job_title_id),
    CONSTRAINT FK_emp_department FOREIGN KEY (department_id) REFERENCES department(department_id)
);

CREATE TABLE employee_salary (
    salary_id INT PRIMARY KEY,
    employee_id INT NOT NULL,
    salary_amount INT NOT NULL,
    valid_from DATE NOT NULL,
    CONSTRAINT FK_salary_employee FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

CREATE TABLE skill (
    skill_id INT PRIMARY KEY,
    skill_name VARCHAR(500) NOT NULL
);

CREATE TABLE employee_skill (
    employee_id INT NOT NULL,
    skill_id INT NOT NULL,
    PRIMARY KEY (employee_id, skill_id),
    CONSTRAINT FK_es_emp FOREIGN KEY (employee_id) REFERENCES employee(employee_id),
    CONSTRAINT FK_es_skill FOREIGN KEY (skill_id) REFERENCES skill(skill_id)
);

-- ============================================================
-- TEACHING ACTIVITIES + ALLOCATION
-- ============================================================

CREATE TABLE teaching_activity (
    activity_type_id INT PRIMARY KEY,
    activity_name VARCHAR(100) NOT NULL UNIQUE,
    factor DECIMAL(5,2) NOT NULL
);

CREATE TABLE planned_activity (
    planned_activity_id INT PRIMARY KEY,
    instance_id INT NOT NULL,
    employee_id INT NOT NULL,
    activity_type_id INT NOT NULL,
    planned_hours DECIMAL(5,2) NOT NULL,
    CONSTRAINT FK_pa_instance FOREIGN KEY (instance_id) REFERENCES course_instance(instance_id),
    CONSTRAINT FK_pa_employee FOREIGN KEY (employee_id) REFERENCES employee(employee_id),
    CONSTRAINT FK_pa_activity FOREIGN KEY (activity_type_id) REFERENCES teaching_activity(activity_type_id)
);

CREATE TABLE allocation (
    planned_activity_id INT NOT NULL,
    employee_id INT NOT NULL,
    allocated_hours DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (planned_activity_id, employee_id),
    CONSTRAINT FK_alloc_activity FOREIGN KEY (planned_activity_id) REFERENCES planned_activity(planned_activity_id),
    CONSTRAINT FK_alloc_employee FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

-- ============================================================
-- SYSTEM RULES
-- ============================================================

CREATE TABLE system_rules (
    rule_name VARCHAR(50) PRIMARY KEY,
    rule_value VARCHAR(20) NOT NULL
);

INSERT INTO system_rules (rule_name, rule_value)
VALUES ('max_course_instances_per_period','4');

-- ============================================================
-- DATASET
-- ============================================================

-- PERSONS
INSERT INTO person (person_id, first_name, last_name, address, personal_number)
VALUES
(1, 'Anna', 'Svensson', 'Götgatan 22, 118 46 Stockholm', '900101-1234'),
(2, 'Johan', 'Lindberg', 'Storgatan 15, 411 24 Göteborg', '850303-5678'),
(3, 'Elin', 'Karlsson', 'Drottninggatan 5, 702 10 Örebro', '780812-9876'),
(4, 'Markus', 'Nyström', 'Västra Hamngatan 9, 211 17 Malmö', '920215-4433'),
(5, 'Sara', 'Ekström', 'Köpmangatan 3, 972 33 Luleå', '950612-8181'),
(6, 'Niklas', 'Berg', 'Skeppsbron 8, 111 30 Stockholm', '880701-1111'),
(7, 'Linda', 'Holm', 'Östra Storgatan 42, 553 21 Jönköping', '910505-2222'),
(8, 'Peter', 'Ström', 'Nygatan 11, 903 27 Umeå', '870312-3333'),
(9, 'Maria', 'Hansson', 'Kungsgatan 14, 791 71 Falun', '930101-4444'),
(10, 'Felix', 'Andersson', 'Södra Förstadsgatan 18, 214 20 Malmö', '890909-5555');

-- PHONE NUMBERS
INSERT INTO phone_number (phone_number, person_id)
VALUES
('0701234567',1),('0702345678',2),('0703456789',3),('0704567890',4),('0705678901',5),
('0706789012',6),('0707890123',7),('0708901234',8),('0709012345',9),('0700123456',10);

-- JOB TITLES
INSERT INTO job_title (job_title_id, jobtitle)
VALUES
(1,'Lecturer'),
(2,'Assistant Professor'),
(3,'Professor'),
(4,'Adjunct');

-- DEPARTMENT (manager_id temporarily NULL)
INSERT INTO department (department_id, department_name, manager_id)
VALUES
(10, 'Department of Computer Science', NULL);

-- EMPLOYEES (manager_id points to self or will be updated later)
INSERT INTO employee (employee_id, person_id, job_title_id, department_id, manager_id)
VALUES
(1,1,3,10,1),
(2,2,2,10,1),
(3,3,1,10,1),
(4,4,4,10,1),
(5,5,1,10,1),
(6,6,2,10,1),
(7,7,2,10,1),
(8,8,1,10,1),
(9,9,1,10,1),
(10,10,2,10,1);

-- Now update department to assign manager
UPDATE department SET manager_id = 1 WHERE department_id = 10;

-- Add FK for department.manager_id now
ALTER TABLE department
ADD CONSTRAINT fk_dept_manager FOREIGN KEY (manager_id) REFERENCES employee(employee_id);

-- Add FK for employee.manager_id now
ALTER TABLE employee
ADD CONSTRAINT FK_emp_manager FOREIGN KEY (manager_id) REFERENCES employee(employee_id);

-- EMPLOYEE SALARY
INSERT INTO employee_salary (salary_id, salary_amount, valid_from, employee_id)
VALUES
(1, 52000, '2025-01-01',1),
(2, 43000, '2025-01-01',2),
(3, 39000, '2025-01-01',3),
(4, 36000, '2025-01-01',4),
(5, 38500, '2025-01-01',5),
(6, 44000, '2025-01-01',6),
(7, 41000, '2025-01-01',7),
(8, 40000, '2025-01-01',8),
(9, 39500, '2025-01-01',9),
(10,42000, '2025-01-01',10);

-- SKILLS
INSERT INTO skill (skill_id, skill_name)
VALUES
(1,'Java'),(2,'Databases'),(3,'Networks'),(4,'Operating Systems'),(5,'Algorithms');

-- EMPLOYEE_SKILL
INSERT INTO employee_skill (skill_id, employee_id)
VALUES
(2,1),(1,2),(4,3),(3,4),(5,5),(2,6),(3,7),(2,8),(1,9),(5,10);

-- COURSES
INSERT INTO course (course_id, course_code, course_name)
VALUES
(200,'IV1351','Database Design'),
(201,'SF1225','Web Development'),
(202,'IV1352','Object-Oriented Programming'),
(203,'SF1301','Computer Networks'),
(204,'IV1400','Cybersecurity Fundamentals');

-- COURSE LAYOUT VERSIONS
INSERT INTO course_layout_version (layout_version_id, course_id, hp, layout_version, valid_from, min_students, max_students)
VALUES
(1,200,7.5,'v1','2025-01-01',10,30),
(2,200,15.0,'v2','2025-08-01',10,35),
(3,201,10.0,'v1','2025-01-01',15,40),
(4,201,12.5,'v2','2025-08-01',15,45),
(5,202,7.5,'v1','2025-01-01',10,30),
(6,203,10.0,'v1','2025-01-01',12,35),
(7,204,12.5,'v1','2025-01-01',8,25);

-- COURSE INSTANCES
INSERT INTO course_instance (instance_id, layout_version_id, num_students, study_period, study_year, admin_hours, exam_hours)
VALUES
(202550273,1,25,'P1',2025,10.0,5.0),
(202550274,2,30,'P2',2025,12.0,6.0),
(202550275,3,28,'P1',2025,8.0,4.0),
(202550276,4,32,'P2',2025,9.0,4.5),
(202550277,5,20,'P3',2025,7.0,3.0),
(202550278,6,22,'P3',2025,6.0,3.0),
(202550279,7,18,'P4',2025,5.0,2.5),
(202550280,3,25,'P4',2025,7.5,3.5),
(202550281,1,30,'P3',2025,9.0,4.0),
(202550282,2,20,'P1',2025,6.5,3.5),
(202550283,4,15,'P2',2025,5.0,2.0),
(202550284,5,18,'P4',2025,6.0,3.0);

-- TEACHING ACTIVITIES
INSERT INTO teaching_activity (activity_type_id, activity_name, factor)
VALUES
(1,'Lecture',3.6),
(2,'Lab',2.4),
(3,'Tutorial',2.4),
(4,'Seminar',1.8);

-- PLANNED ACTIVITIES
INSERT INTO planned_activity (planned_activity_id, planned_hours, activity_type_id, employee_id, instance_id)
VALUES
(500,10.0,1,1,202550273),
(501,8.0,3,1,202550273),
(502,12.0,1,2,202550274),
(503,10.0,1,3,202550275),
(504,9.0,3,3,202550275),
(505,7.0,1,4,202550276),
(506,8.0,1,5,202550277),
(507,5.0,2,6,202550278),
(508,6.0,1,7,202550279),
(509,5.0,1,8,202550280),
(510,4.0,2,9,202550281),
(511,6.0,3,10,202550282),
(512,5.0,1,1,202550283),
(513,3.0,2,2,202550284);

-- ALLOCATIONS
INSERT INTO allocation (planned_activity_id, employee_id, allocated_hours)
VALUES
(500,1,10.0),
(501,1,8.0),
(502,2,12.0),
(503,3,10.0),
(504,3,9.0),
(505,4,7.0),
(506,5,8.0),
(507,6,5.0),
(508,7,6.0),
(509,8,5.0),
(510,9,4.0),
(511,10,6.0),
(512,1,5.0),
(513,2,3.0);

-- ============================================================
-- SAMPLE QUERY
-- ============================================================

SELECT 
    ci.instance_id,
    c.course_code,
    c.course_name,
    ci.study_period,
    p.first_name || ' ' || p.last_name AS teacher
FROM course_instance ci
JOIN course_layout_version clv ON ci.layout_version_id = clv.layout_version_id
JOIN course c ON clv.course_id = c.course_id
JOIN planned_activity pa ON ci.instance_id = pa.instance_id
JOIN employee e ON pa.employee_id = e.employee_id
JOIN person p ON e.person_id = p.person_id
ORDER BY ci.study_period, course_code;
