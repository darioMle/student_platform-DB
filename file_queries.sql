-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- This document will consist of:
-- general insert queries
-- general queries
-- queries that interact with the views


-- General insert queries, using my data for reference
-- (run in this order, since later inserts look up rows created by earlier ones)

-- Add a school
INSERT INTO `schools` (`name`)
VALUES ('St Thomas of Aquin''s');

-- Add a student to that school
INSERT INTO `students` (`name`, `year`, `school_id`, `gender`, `enrollment_date`)
SELECT 'Dario Moretti', 'S4', `id`, 'male', '2026-01-02'
FROM `schools`
WHERE `name` = 'St Thomas of Aquin''s';

-- Add a subject
INSERT INTO `subjects` (`name`, `department`)
VALUES ('Mathematics', 'Sciences');

-- Add a teacher
INSERT INTO `teachers` (`name`, `department`)
VALUES ('Mr Rafferty', 'Sciences');

-- Enroll the student in the subject with that teacher
INSERT INTO `enrollments` (`student_id`, `subject_id`, `year`, `teacher_id`)
SELECT `students`.`id`, `subjects`.`id`, '2026', `teachers`.`id`
FROM `students`
JOIN `teachers`
JOIN `subjects`
WHERE `students`.`name` = 'Dario Moretti'
AND `subjects`.`name` = 'Mathematics'
AND `teachers`.`name` = 'Mr Rafferty';

-- Add an assessment for the subject
INSERT INTO `assessments` (`subject_id`, `name`, `date`)
SELECT `id`, 'Math Test 1', '2026-10-24'
FROM `subjects`
WHERE `name` = 'Mathematics';

-- Record the student's score in that assessment
INSERT INTO `scores` (`student_id`, `assessment_id`, `percentage`)
SELECT `students`.`id`, `assessments`.`id`, '96'
FROM `students`
JOIN `assessments`
WHERE `students`.`name` = 'Dario Moretti'
AND `assessments`.`name` = 'Math Test 1';

-- Log a study session (duration in minutes)
INSERT INTO `study_sessions` (`student_id`, `subject_id`, `duration`, `date`)
SELECT `students`.`id`, `subjects`.`id`, '76', '2026-01-04'
FROM `students`
JOIN `subjects`
WHERE `students`.`name` = 'Dario Moretti'
AND `subjects`.`name` = 'Mathematics';

-- Record attendance
INSERT INTO `attendance` (`student_id`, `subject_id`, `status`, `date`)
SELECT `students`.`id`, `subjects`.`id`, 'late', '2026-01-06'
FROM `students`
JOIN `subjects`
WHERE `students`.`name` = 'Dario Moretti'
AND `subjects`.`name` = 'Mathematics';

-- Record a wellbeing survey
INSERT INTO `wellbeing_surveys` (`student_id`, `sleep_hours`, `stress_level`, `mood`, `date`)
SELECT `id`, '8', '2', 'sleepy', '2026-01-02'
FROM `students`
WHERE `name` = 'Dario Moretti';

-- Share a resource
INSERT INTO `resources` (`student_id`, `subject_id`, `type`, `url`, `date`)
SELECT `students`.`id`, `subjects`.`id`, 'website', 'https://www.national5maths.co.uk/', '2026-01-09'
FROM `students`
JOIN `subjects`
WHERE `students`.`name` = 'Dario Moretti'
AND `subjects`.`name` = 'Mathematics';

-- Like that resource
INSERT INTO `likes` (`student_id`, `resource_id`)
SELECT `students`.`id`, `resources`.`id`
FROM `students`
JOIN `resources`
ON `resources`.`student_id` = `students`.`id`
WHERE `students`.`name` = 'Dario Moretti'
AND `resources`.`url` = 'https://www.national5maths.co.uk/';


-- General queries

-- Students at a school with 100 or more lates this year
SELECT `students`.`name` AS `100 or more lates`,
    SUM(`attendance`.`status` = 'late') AS `total_lates`
FROM `students`
JOIN `attendance`
ON `attendance`.`student_id` = `students`.`id`
WHERE `students`.`school_id` = (
    SELECT `id` FROM `schools`
    WHERE `name` = 'St Thomas of Aquin''s'
)
AND `attendance`.`date` BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY `students`.`id`
HAVING SUM(`attendance`.`status` = 'late') >= 100;

-- All subjects in the Sciences department
SELECT `name` FROM `subjects`
WHERE `department` = 'Sciences';

-- All assessments for Mathematics
SELECT `name` FROM `assessments`
WHERE `subject_id` = (
    SELECT `id` FROM `subjects`
    WHERE `name` = 'Mathematics'
);

-- Average study session length (minutes) for Mathematics at a school
SELECT AVG(`study_sessions`.`duration`) AS `avg_studying_math`
FROM `study_sessions`
JOIN `students`
ON `students`.`id` = `study_sessions`.`student_id`
JOIN `subjects`
ON `subjects`.`id` = `study_sessions`.`subject_id`
WHERE `students`.`school_id` = (
    SELECT `id` FROM `schools`
    WHERE `name` = 'St Thomas of Aquin''s'
)
AND `subjects`.`name` = 'Mathematics';

-- Most common moods at a school this year
SELECT `wellbeing_surveys`.`mood`, COUNT(*) AS `num_this_year`
FROM `wellbeing_surveys`
JOIN `students`
ON `students`.`id` = `wellbeing_surveys`.`student_id`
WHERE `students`.`school_id` = (
    SELECT `id` FROM `schools`
    WHERE `name` = 'St Thomas of Aquin''s'
)
AND `wellbeing_surveys`.`date` BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY `wellbeing_surveys`.`mood`
ORDER BY `num_this_year` DESC;


-- Using the views

-- Total number of students
SELECT * FROM `number_of_users`;

-- Most popular subjects
SELECT * FROM `popular_subjects`;

-- Average score against attendance
SELECT * FROM `relationship_attendance`;

-- Average score against study time
SELECT * FROM `relationship_study`;

-- Students who may need support at one school
SELECT * FROM `support`
WHERE `school_name` = 'St Thomas of Aquin''s';

-- Most-liked resources
SELECT * FROM `useful_resources`;
