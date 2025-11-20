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
 course_id  SERIAL NOT NULL,
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
 department_name VARCHAR(200)UNIQUE
);

ALTER TABLE department ADD CONSTRAINT PK_department PRIMARY KEY (department_id);


CREATE TABLE job_title (
 job_title_id SERIAL NOT NULL,
 jobtitle CHAR(10) UNIQUE
);

ALTER TABLE job_title ADD CONSTRAINT PK_job_title PRIMARY KEY (job_title_id);


CREATE TABLE person (
 person_id SERIAL NOT NULL,
 first_name VARCHAR(20),
 last_name VARCHAR(10),
 phone_number INT,
 address VARCHAR(100),
 personal_number VARCHAR(13)
);

ALTER TABLE person ADD CONSTRAINT PK_person PRIMARY KEY (person_id);


CREATE TABLE phone_number (
 phone_number VARCHAR(10) NOT NULL,
 person_id INT NOT NULL
);

ALTER TABLE phone_number ADD CONSTRAINT PK_phone_number PRIMARY KEY (phone_number,person_id);


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
 manager VARCHAR(100),
 department_id INT NOT NULL,
 job_title_id INT NOT NULL,
 skill_set VARCHAR(500) NOT NULL,
 person_id INT NOT NULL
);

ALTER TABLE employee ADD CONSTRAINT PK_employee PRIMARY KEY (employee_id);


CREATE TABLE manager (
 department_id INT NOT NULL,
 employee_id INT NOT NULL
);

ALTER TABLE manager ADD CONSTRAINT PK_manager PRIMARY KEY (department_id,employee_id);


CREATE TABLE planned_activity (
 planned_activity_id SERIAL NOT NULL,
 instance_id INT NOT NULL,
 planned_hours DECIMAL(10,2),
 activity_type_id INT NOT NULL,
 employee_id VARCHAR(10) NOT NULL
);

ALTER TABLE planned_activity ADD CONSTRAINT PK_planned_activity PRIMARY KEY (planned_activity_id,instance_id);


CREATE TABLE skill_set (
 employee_id INT NOT NULL,
 skill_set VARCHAR(500)
);

ALTER TABLE skill_set ADD CONSTRAINT PK_skill_set PRIMARY KEY (employee_id);


CREATE TABLE allocation (
 employee_id_0 INT NOT NULL,
 planned_activity_id INT NOT NULL,
 instance_id INT NOT NULL,
 allocated_hours DECIMAL(10,2)
);

ALTER TABLE allocation ADD CONSTRAINT PK_allocation PRIMARY KEY (employee_id_0,planned_activity_id,instance_id);



--trigger
-- First, create the trigger function
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
    SELECT COUNT(DISTINCT a.instance_id) INTO allocation_count
    FROM allocation a
    JOIN planned_activity pa ON a.planned_activity_id = pa.planned_activity_id
    JOIN course_instance ci ON pa.instance_id = ci.instance_id
    WHERE a.employee_id_0 = NEW.employee_id_0
      AND ci.study_period = current_period;

    -- If allocation_count is already 4, raise an exception
    IF allocation_count >= 4 THEN
        RAISE EXCEPTION 'Teacher % is already allocated to 4 course instances in period %', NEW.employee_id_0, current_period;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Now, create the trigger on the allocation table
CREATE TRIGGER trg_check_teacher_allocation
BEFORE INSERT OR UPDATE ON allocation
FOR EACH ROW
EXECUTE FUNCTION check_teacher_allocation();
--trigger



ALTER TABLE phone_number ADD CONSTRAINT FK_phone_number_0 FOREIGN KEY (person_id) REFERENCES person (person_id) ON DELETE RESTRICT;


ALTER TABLE course_instance ADD CONSTRAINT FK_course_instance_0 FOREIGN KEY (course_id) REFERENCES course_layout (course_id) ON DELETE RESTRICT;


ALTER TABLE employee ADD CONSTRAINT FK_employee_0 FOREIGN KEY (department_id) REFERENCES department (department_id) ON DELETE RESTRICT;
ALTER TABLE employee ADD CONSTRAINT FK_employee_1 FOREIGN KEY (job_title_id) REFERENCES job_title (job_title_id) ON DELETE RESTRICT;
ALTER TABLE employee ADD CONSTRAINT FK_employee_2 FOREIGN KEY (person_id) REFERENCES person (person_id)ON DELETE RESTRICT;


ALTER TABLE manager ADD CONSTRAINT FK_manager_0 FOREIGN KEY (department_id) REFERENCES department (department_id) ON DELETE RESTRICT;
ALTER TABLE manager ADD CONSTRAINT FK_manager_1 FOREIGN KEY (employee_id) REFERENCES employee (employee_id)ON DELETE RESTRICT;


ALTER TABLE planned_activity ADD CONSTRAINT FK_planned_activity_0 FOREIGN KEY (instance_id) REFERENCES course_instance (instance_id)ON DELETE RESTRICT;
ALTER TABLE planned_activity ADD CONSTRAINT FK_planned_activity_1 FOREIGN KEY (activity_type_id) REFERENCES teaching_activity (activity_type_id)ON DELETE RESTRICT;


ALTER TABLE skill_set ADD CONSTRAINT FK_skill_set_0 FOREIGN KEY (employee_id) REFERENCES employee (employee_id) ON DELETE CASCADE;


ALTER TABLE allocation ADD CONSTRAINT FK_allocation_0 FOREIGN KEY (employee_id_0) REFERENCES employee (employee_id)ON DELETE CASCADE;
ALTER TABLE allocation ADD CONSTRAINT FK_allocation_1 FOREIGN KEY (planned_activity_id,instance_id) REFERENCES planned_activity (planned_activity_id,instance_id) ON DELETE RESTRICT;





































INSERT INTO course_layout (course_name, min_students, max_students, hp, layout_version, valid_from, course_code) VALUES
('Math', 5, 30, 7.5, 1.0, '2023-08-01', 'SF1234'),
('Physics', 10, 40, 7.5, 1.0, '2023-08-01', 'RD2536'),
('Chemistry', 8, 35, 7.5, 1.0, '2023-08-01', 'CH8376'),
('Biology', 6, 30, 7.5, 1.0, '2023-08-01', 'BU3749'),
('English', 10, 50, 5.0, 1.0, '2023-08-01', 'IV2748'),
('History ', 5, 40, 5.0, 1.0, '2023-08-01', 'IH7384'),
('CS', 12, 50, 10.0, 1.0, '2023-08-01', 'KI773'),
('Art', 5, 25, 5.0, 1.0, '2023-08-01', 'ZX8372'),
('Music', 3, 20, 5.0, 1.0, '2023-08-01', 'MU4800'),
('Philosophy', 5, 30, 5.0, 1.0, '2023-08-01', 'PH4899');

-- department
INSERT INTO department (department_name) VALUES
('Mathematics'),('Physics'),('Chemistry'),('Biology'),('English'),
('History'),('Computer Science'),('Art'),('Music'),('Philosophy');

-- job_title
INSERT INTO job_title (jobtitle) VALUES
('Professor'),('Lecturer'),('AsstProf'),('LabAsst'),('Researcher'),
('Tutor'),('Admin'),('Ordinator'),('Manager'),('HR');

-- person
INSERT INTO person (first_name, last_name, phone_number, address, personal_number) VALUES
('John','Doe',123456789,' 123 Gamla stan','19900101-1234'),
('Jane','Smith',234567890,'456 Hornstull','19920202-2345'),
('Alice','Brown',345678901,'789 Jakobsberg','19880505-3456'),
('Bob','Johnson',456789012,'101 Hornstull','19930303-4567'),
('Eve','Davis',567890123,'202 Kalmgata','19950505-5678'),
('Charlie','Miller',678901234,'303 Centralgata','19960606-6789'),
('Grace','Wilson',789012345,'404 Brygggata','19970707-7890'),
('Oscar','Moore',890123456,'505 Halpersgata','19980808-8901'),
('Mia','Taylor',901234567,'606 Jijigata','19990909-9012'),
('Leo','Anderson',123123123,'707 Najs Gata','20000101-0123');

-- phone_number
INSERT INTO phone_number (phone_number, person_id) VALUES
('123456789',1),('234567890',2),('345678901',3),('456789012',4),('567890123',5),
('678901234',6),('789012345',7),('890123456',8),('901234567',9),('123123123',10);

-- teaching_activity
INSERT INTO teaching_activity (activity_name, factor) VALUES
('Lecture',3.6),('Lab',2.4),('Tutorial',2.4),('Seminar',1.8);

-- course_instance
INSERT INTO course_instance (num_students, study_period, study_year, admin_hours, exam_hours, course_id) VALUES
(25,'P1',2023,10.0,5.0,1),(30,'P1',2023,12.0,6.0,2),(20,'P2',2023,8.0,4.0,3),
(15,'P2',2023,9.0,4.5,4),(40,'P1',2023,11.0,5.5,5),(35,'P2',2023,10.0,5.0,6),
(50,'P3',2023,15.0,7.0,7),(20,'P4',2023,7.0,3.5,8),(10,'P3',2023,6.0,2.5,9),
(30,'P4',2023,9.0,4.0,10);

-- employee
INSERT INTO employee (salary, "manager", department_id, job_title_id, skill_set, person_id) VALUES
(50000,'Jane Smith',1,1,'Math, Teaching',1),
(45000,'John Doe',2,2,'Physics, Research',2),
(40000,'Alice Brown',3,3,'Chemistry, Lab',3),
(42000,'Bob Johnson',4,4,'Biology, Tutoring',4),
(47000,'Eve Davis',5,5,'English, Management',5),
(48000,'Charlie Miller',6,6,'History, Events',6),
(55000,'Grace Wilson',7,7,'CS, Leadership',7),
(43000,'Oscar Moore',8,2,'Art, Design',8),
(41000,'Mia Taylor',9,3,'Music, Teaching',9),
(46000,'Leo Anderson',10,1,'Philosophy, Analysis',10);

-- manager
INSERT INTO manager (department_id, employee_id) VALUES
(1,7),(2,8),(3,1),(4,2),(5,5),(6,4);

-- planned_activity
INSERT INTO planned_activity (instance_id, planned_hours, activity_type_id, employee_id) VALUES
(1,10.0,1,1),
(2,8.0,2,2),
(3,6.0,3,3),
(4,5.0,4,4);

-- skill_set
INSERT INTO skill_set (employee_id, skill_set) VALUES
(1,'Math, Algebra'),(2,'Physics, Mechanics'),(3,'Chemistry, Lab'),(4,'Biology, Experiments'),(5,'English, Writing'),
(6,'History, Research'),(7,'CS, Programming'),(8,'Art, Painting'),(9,'Music, Instruments'),(10,'Philosophy, Logic');

-- allocation
INSERT INTO allocation (employee_id_0, planned_activity_id, instance_id, allocated_hours) VALUES
(1,1,1,10.0),
(2,2,2,8.0),
(3,3,3,6.0),
(4,4,4,5.0);

--test_queries
SELECT d.department_id, d.department_name, e.employee_id, e.salary, p.first_name, p.last_name
FROM department d
LEFT JOIN employee e ON e.department_id = d.department_id
LEFT JOIN person p ON e.person_id = p.person_id;
