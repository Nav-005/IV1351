-- Drop tables in reverse dependency order to avoid FK errors
DROP TABLE IF EXISTS allocation CASCADE;
DROP TABLE IF EXISTS skill_set CASCADE;
DROP TABLE IF EXISTS planned_activity CASCADE;
DROP TABLE IF EXISTS manager CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS course_instance CASCADE;
DROP TABLE IF EXISTS teaching_activity CASCADE;
DROP TABLE IF EXISTS phone_number CASCADE;
DROP TABLE IF EXISTS person CASCADE;
DROP TABLE IF EXISTS job_title CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS course_layout CASCADE;





CREATE TABLE course_layout (
 course_id SERIAL NOT NULL,
 course_name VARCHAR(500),
 min_students INT,
 max_students INT,
 hp DECIMAL(10),
 layout_version DECIMAL(10),
 valid_from DATE,
 course_code CHAR(10)
);

ALTER TABLE course_layout ADD CONSTRAINT PK_course_layout PRIMARY KEY (course_id);


CREATE TABLE department (
 department_id SERIAL NOT NULL,
 department_name VARCHAR(200) UNIQUE,
 manager_id INT NOT NULL
);

ALTER TABLE department ADD CONSTRAINT PK_department PRIMARY KEY (department_id);


CREATE TABLE job_title (
 job_title_id SERIAL NOT NULL,
 jobtitle CHAR(10)
);

ALTER TABLE job_title ADD CONSTRAINT PK_job_title PRIMARY KEY (job_title_id);


CREATE TABLE person (
 person_id SERIAL NOT NULL,
 first_name VARCHAR(20),
 last_name VARCHAR(10),
 address VARCHAR(100),
 personal_number VARCHAR(13)
);

ALTER TABLE person ADD CONSTRAINT PK_person PRIMARY KEY (person_id);


CREATE TABLE phone_number (
 phone_number VARCHAR(10) NOT NULL,
 person_id INT NOT NULL
);

ALTER TABLE phone_number ADD CONSTRAINT PK_phone_number PRIMARY KEY (phone_number,person_id);


CREATE TABLE skill (
 skill_id SERIAL NOT NULL,
 skill_name VARCHAR(500)
);

ALTER TABLE skill ADD CONSTRAINT PK_skill PRIMARY KEY (skill_id);


CREATE TABLE teaching_activity (
 activity_type_id SERIAL NOT NULL,
 activity_name VARCHAR(100) UNIQUE,
 factor DECIMAL(10,2)
);

ALTER TABLE teaching_activity ADD CONSTRAINT PK_teaching_activity PRIMARY KEY (activity_type_id);


CREATE TABLE course_instance (
 instance_id SERIAL NOT NULL,
 num_students INT,
 study_period CHAR(2),
 study_year INT,
 admin_hours DECIMAL(10,2),
 exam_hours DECIMAL(10,2),
 course_id INT NOT NULL
);

ALTER TABLE course_instance ADD CONSTRAINT PK_course_instance PRIMARY KEY (instance_id);


CREATE TABLE employee (
 employee_id SERIAL NOT NULL,
 salary INT,
 manager_id INT NOT NULL,
 job_title_id INT NOT NULL,
 skill_set VARCHAR(500) NOT NULL,
 person_id INT NOT NULL,
 department_id INT NOT NULL
);

ALTER TABLE employee ADD CONSTRAINT PK_employee PRIMARY KEY (employee_id);


CREATE TABLE employee_skill (
 skill_id SERIAL NOT NULL,
 employee_id INT NOT NULL
);

ALTER TABLE employee_skill ADD CONSTRAINT PK_employee_skill PRIMARY KEY (skill_id,employee_id);


CREATE TABLE planned_activity (
 planned_activity_id SERIAL NOT NULL,
 planned_hours DECIMAL(10,2),
 activity_type_id INT NOT NULL,
 employee_id INT NOT NULL,
 instance_id INT NOT NULL
);

ALTER TABLE planned_activity ADD CONSTRAINT PK_planned_activity PRIMARY KEY (planned_activity_id);


CREATE TABLE allocation (
 planned_activity_id SERIAL NOT NULL,
 employee_id INT NOT NULL,
 allocated_hours DECIMAL(10,2)
);

ALTER TABLE allocation ADD CONSTRAINT PK_allocation PRIMARY KEY (planned_activity_id,employee_id);



-- Trigger function to prevent more than 4 course instances per employee per study period
CREATE OR REPLACE FUNCTION check_teacher_allocation()
RETURNS TRIGGER AS $$
DECLARE
    current_period CHAR(2);
    allocation_count INT;
BEGIN
    -- Get the study period of the planned activity being allocated
    SELECT ci.study_period INTO current_period
    FROM planned_activity pa
    JOIN course_instance ci ON pa.instance_id = ci.instance_id
    WHERE pa.planned_activity_id = NEW.planned_activity_id;

    -- Count how many distinct course instances this employee is already allocated to in this period
    SELECT COUNT(DISTINCT pa.instance_id) INTO allocation_count
    FROM allocation a
    JOIN planned_activity pa ON a.planned_activity_id = pa.planned_activity_id
    JOIN course_instance ci ON pa.instance_id = ci.instance_id
    WHERE a.employee_id = NEW.employee_id
      AND ci.study_period = current_period;

    -- If allocation_count is already 4, raise an exception
    IF allocation_count >= 4 THEN
        RAISE EXCEPTION 'Employee % is already allocated to 4 course instances in period %', NEW.employee_id, current_period;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on allocation table
CREATE TRIGGER trg_check_teacher_allocation
BEFORE INSERT OR UPDATE ON allocation
FOR EACH ROW
EXECUTE FUNCTION check_teacher_allocation();


ALTER TABLE phone_number ADD CONSTRAINT FK_phone_number_0 FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE CASDADE;


ALTER TABLE course_instance ADD CONSTRAINT FK_course_instance_0 FOREIGN KEY (course_id) REFERENCES course_layout (course_id) ON DELETE RESTRICT;


ALTER TABLE employee ADD CONSTRAINT FK_employee_0 FOREIGN KEY (job_title_id) REFERENCES job_title (job_title_id) ON DELETE RESTRICT;
ALTER TABLE employee ADD CONSTRAINT FK_employee_1 FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE RESTRICT;
ALTER TABLE employee ADD CONSTRAINT FK_employee_2 FOREIGN KEY (department_id) REFERENCES department (department_id) ON DELETE RESTRICT;


ALTER TABLE employee_skill ADD CONSTRAINT FK_employee_skill_0 FOREIGN KEY (skill_id) REFERENCES skill (skill_id) OON DELETE RESTRICT;
ALTER TABLE employee_skill ADD CONSTRAINT FK_employee_skill_1 FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE CASCADE;


ALTER TABLE planned_activity ADD CONSTRAINT FK_planned_activity_0 FOREIGN KEY (activity_type_id) REFERENCES teaching_activity (activity_type_id) ON DELETE RESTRICT;
ALTER TABLE planned_activity ADD CONSTRAINT FK_planned_activity_1 FOREIGN KEY (instance_id) REFERENCES course_instance (instance_id) ON DELETE RESTRICT;


ALTER TABLE allocation ADD CONSTRAINT FK_allocation_0 FOREIGN KEY (planned_activity_id) REFERENCES planned_activity (planned_activity_id) ON DELETE RESTRICT;
ALTER TABLE allocation ADD CONSTRAINT FK_allocation_1 FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE SET RESTRICT;



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
('Tutor'),('Admin'),('Coordinator'),('Manager'),('HR');

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
(8,1),(9,2),(10,3),(1,4),(2,5);

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
INSERT INTO planned_activity (planned_hours, activity_type_id, employee_id, instance_id) VALUES
(10.0,1,1,1),(8.0,2,2,2),(6.0,3,3,3),(5.0,4,4,4),(12.0,5,5,5),
(9.0,6,6,6),(7.0,7,7,7),(11.0,8,8,8),(4.0,9,9,9),(3.0,10,10,10);

-- ALLOCATIONS
INSERT INTO allocation (planned_activity_id, employee_id, allocated_hours) VALUES
(1,1,10.0),(2,2,8.0),(3,3,6.0),(4,4,5.0),(5,5,12.0),
(6,6,9.0),(7,7,7.0),(8,8,11.0),(9,9,4.0),(10,10,3.0);


--test_queries
SELECT d.department_id, d.department_name, e.employee_id, e.salary, p.first_name, p.last_name
FROM department d
LEFT JOIN employee e ON e.department_id = d.department_id
LEFT JOIN person p ON e.person_id = p.person_id;






