-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

-- Tables

-- Schools that students attend
CREATE TABLE `schools`(
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(32) UNIQUE NOT NULL,
    PRIMARY KEY(`id`)
);

-- Students, each belonging to exactly one school
CREATE TABLE `students`(
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(32) NOT NULL,
    `year` ENUM('S1', 'S2', 'S3', 'S4', 'S5', 'S6') NOT NULL,
    `school_id` INT NOT NULL,
    `gender` ENUM('male', 'female', 'other') NOT NULL,
    `enrollment_date` DATE NOT NULL,
    PRIMARY KEY(`id`),
    FOREIGN KEY (`school_id`) REFERENCES `schools`(`id`)
);

-- Teachers (department is optional)
CREATE TABLE `teachers`(
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(32) NOT NULL,
    `department` VARCHAR(32),
    PRIMARY KEY(`id`)
);

-- Subjects that can be studied
CREATE TABLE `subjects`(
    `id` INT AUTO_INCREMENT,
    `name` VARCHAR(32) UNIQUE NOT NULL,
    `department` VARCHAR(32),
    PRIMARY KEY(`id`)
);

-- Which student takes which subject, with which teacher, in which year
-- The UNIQUE key stops a student being enrolled in the same subject twice in a year
CREATE TABLE `enrollments`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `year` YEAR NOT NULL,
    `teacher_id` INT NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE(`student_id`, `subject_id`, `year`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`subject_id`) REFERENCES `subjects`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`teacher_id`) REFERENCES `teachers`(`id`)
        ON DELETE CASCADE
);

-- Tests and other assessments for a subject
CREATE TABLE `assessments`(
    `id` INT AUTO_INCREMENT,
    `subject_id` INT NOT NULL,
    `name` VARCHAR(22) NOT NULL,
    `date` DATE NOT NULL,
    PRIMARY KEY(`id`),
    FOREIGN KEY(`subject_id`) REFERENCES `subjects`(`id`)
        ON DELETE CASCADE
);

-- A student's result in an assessment, as a percentage from 0 to 100
CREATE TABLE `scores`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `assessment_id` INT NOT NULL,
    `percentage` TINYINT NOT NULL CHECK(`percentage` >= 0 AND `percentage` <= 100),
    PRIMARY KEY(`id`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`assessment_id`) REFERENCES `assessments`(`id`)
        ON DELETE CASCADE
);

-- Study sessions logged by students
CREATE TABLE `study_sessions`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `duration` INT NOT NULL, -- meant to be in minutes
    `date` DATE NOT NULL,
    PRIMARY KEY(`id`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`subject_id`) REFERENCES `subjects`(`id`)
        ON DELETE CASCADE
);

-- Attendance for a subject on a date
-- The UNIQUE key stops two attendance records for the same student, subject and day
CREATE TABLE `attendance`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `status` ENUM('absent', 'late', 'present') NOT NULL,
    `date` DATE NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE(`student_id`, `subject_id`, `date`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`subject_id`) REFERENCES `subjects`(`id`)
        ON DELETE CASCADE
);

-- Wellbeing surveys: hours slept, stress from 1 to 10, and a short mood word
CREATE TABLE `wellbeing_surveys`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `sleep_hours` TINYINT NOT NULL,
    `stress_level` TINYINT NOT NULL CHECK(`stress_level` >= 1 AND `stress_level` <= 10),
    `mood` VARCHAR(22) NOT NULL,
    `date` DATE NOT NULL,
    PRIMARY KEY(`id`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE
);

-- Revision resources (e.g. websites) shared by students for a subject
CREATE TABLE `resources`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `type` VARCHAR(22) NOT NULL,
    `url` VARCHAR(255) NOT NULL,
    `date` DATE NOT NULL,
    PRIMARY KEY(`id`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`subject_id`) REFERENCES `subjects`(`id`)
        ON DELETE CASCADE
);

-- Likes on resources
-- The UNIQUE key stops a student liking the same resource more than once
CREATE TABLE `likes`(
    `id` INT AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `resource_id` INT NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE(`student_id`, `resource_id`),
    FOREIGN KEY(`student_id`) REFERENCES `students`(`id`)
        ON DELETE CASCADE,
    FOREIGN KEY(`resource_id`) REFERENCES `resources`(`id`)
        ON DELETE CASCADE
);


-- Views

-- Total number of students
CREATE VIEW `number_of_users` AS
SELECT COUNT(`id`) AS `total_users`
FROM `students`;

-- The ten subjects with the most enrolled students
CREATE VIEW `popular_subjects` AS
SELECT `subjects`.`name`, COUNT(`enrollments`.`student_id`) AS `number_of_students`
FROM `subjects`
JOIN `enrollments`
ON `enrollments`.`subject_id` = `subjects`.`id`
GROUP BY `subjects`.`id`
ORDER BY `number_of_students` DESC
LIMIT 10;

-- Each student's average score next to how many times they were present
-- Scores and attendance are totalled separately first, so one does not multiply the other
CREATE VIEW `relationship_attendance` AS
SELECT `sc`.`average_score`, `att`.`total_present`
FROM (
    SELECT `student_id`, AVG(`percentage`) AS `average_score`
    FROM `scores`
    GROUP BY `student_id`
) AS `sc`
JOIN (
    SELECT `student_id`, SUM(`status` = 'present') AS `total_present`
    FROM `attendance`
    GROUP BY `student_id`
) AS `att`
ON `att`.`student_id` = `sc`.`student_id`
ORDER BY `att`.`total_present` DESC
LIMIT 100;

-- Each student's average score next to their average study session length
CREATE VIEW `relationship_study` AS
SELECT `sc`.`average_score`, `st`.`avg_study`
FROM (
    SELECT `student_id`, AVG(`percentage`) AS `average_score`
    FROM `scores`
    GROUP BY `student_id`
) AS `sc`
JOIN (
    SELECT `student_id`, AVG(`duration`) AS `avg_study`
    FROM `study_sessions`
    GROUP BY `student_id`
) AS `st`
ON `st`.`student_id` = `sc`.`student_id`
ORDER BY `st`.`avg_study` DESC
LIMIT 100;

-- Students who may need support, with the ones in the most difficulty first
-- (lowest attendance, scores and sleep, then highest stress)
CREATE VIEW `support` AS
SELECT `students`.`id`,
    `students`.`name` AS `student_name`,
    `schools`.`name` AS `school_name`,
    `sc`.`average_score`,
    `att`.`total_present`,
    `w`.`avg_sleep`,
    `w`.`avg_stress`
FROM `students`
JOIN `schools`
ON `schools`.`id` = `students`.`school_id`
JOIN (
    SELECT `student_id`, AVG(`percentage`) AS `average_score`
    FROM `scores`
    GROUP BY `student_id`
) AS `sc`
ON `sc`.`student_id` = `students`.`id`
JOIN (
    SELECT `student_id`, SUM(`status` = 'present') AS `total_present`
    FROM `attendance`
    GROUP BY `student_id`
) AS `att`
ON `att`.`student_id` = `students`.`id`
JOIN (
    SELECT `student_id`,
        AVG(`sleep_hours`) AS `avg_sleep`,
        AVG(`stress_level`) AS `avg_stress`
    FROM `wellbeing_surveys`
    GROUP BY `student_id`
) AS `w`
ON `w`.`student_id` = `students`.`id`
ORDER BY `total_present` ASC,
    `average_score` ASC,
    `avg_sleep` ASC,
    `avg_stress` DESC;

-- The 25 most-liked resources
CREATE VIEW `useful_resources` AS
SELECT `resources`.`url`, `resources`.`type`, COUNT(`likes`.`resource_id`) AS `likes`
FROM `resources`
JOIN `likes`
ON `likes`.`resource_id` = `resources`.`id`
GROUP BY `resources`.`id`
ORDER BY `likes` DESC
LIMIT 25;


-- Indexes

-- schools and subjects: none needed, the UNIQUE name already creates an index

-- students table
CREATE INDEX `students_name`
ON `students`(`name`);

-- teachers table
CREATE INDEX `teachers_name`
ON `teachers`(`name`);

CREATE INDEX `teachers_department`
ON `teachers`(`department`);

-- enrollments table
-- student_id is already covered by the UNIQUE key
CREATE INDEX `enrollments_subject_id`
ON `enrollments`(`subject_id`);

CREATE INDEX `enrollments_teacher_id`
ON `enrollments`(`teacher_id`);

-- skipped assessments table since I didn't find it important

-- scores table
CREATE INDEX `scores_student_id`
ON `scores`(`student_id`);

CREATE INDEX `scores_assessment_id`
ON `scores`(`assessment_id`);

-- study sessions table
CREATE INDEX `study_student_id`
ON `study_sessions`(`student_id`);

CREATE INDEX `study_subject_id`
ON `study_sessions`(`subject_id`);

-- attendance table
-- student_id is already covered by the UNIQUE key
CREATE INDEX `attendance_subject_id`
ON `attendance`(`subject_id`);

-- wellbeing table
CREATE INDEX `wellbeing_surveys_sleep`
ON `wellbeing_surveys`(`sleep_hours`);

CREATE INDEX `wellbeing_surveys_stress`
ON `wellbeing_surveys`(`stress_level`);

CREATE INDEX `wellbeing_surveys_student_id`
ON `wellbeing_surveys`(`student_id`);

-- resources table
CREATE INDEX `resources_type`
ON `resources`(`type`);

CREATE INDEX `resources_subject_id`
ON `resources`(`subject_id`);

CREATE INDEX `resources_student_id`
ON `resources`(`student_id`);

-- skipped likes table since the UNIQUE key and the foreign keys already give it indexes
