# Design Document

By Dario Moretti

Video overview: <https://youtu.be/YipXqwm8HqM>

## Scope

The purpose of this database is to bring together the things that influence how well students do at school (attendance, study habits, sleep and stress, and the resources they use) alongside their actual results. It lets a school, or a group of schools, see which subjects are popular, whether attendance and studying are linked to better scores, and which students might need extra support. It also lets students share useful revision resources and "like" the ones that helped them.

Included in the scope:

- Schools, and the students who attend them (year group, gender, enrollment date)
- Teachers and the subjects they teach, along with each student's enrollment in a subject
- Assessments and the scores students get in them
- Study sessions that students log, and attendance for each subject
- Wellbeing surveys (sleep, stress, mood)
- Resources (e.g. websites) that students recommend, and likes on those resources

Outside the scope:

- Parents or guardians, staff other than teachers, and school management
- Timetables, classrooms and individual lesson periods
- Fees, behaviour or disciplinary records, and detailed feedback or report comments
- Grades other than a percentage (e.g. letter grades or predicted grades)
- Login accounts, permissions and any kind of user authentication

## Functional Requirements

A user should be able to:

- Add schools, students, teachers, subjects and enroll students in subjects
- Record assessments, scores, study sessions, attendance and wellbeing survey results
- Add resources and like them
- Run queries such as: which students have 100 or more lates this year, the average time students at a school spend studying a subject, or the most common moods this year
- Use the views to see total users, the most popular subjects, the relationship between attendance/studying and scores, students who may need support, and the most useful resources

Beyond the scope of this database:

- Predicting results or automatically deciding that a student needs help (the `support` view only surfaces students for a person to review)
- Handling timetables, report cards or communication with parents
- Controlling who is allowed to see which data, since that would have to be handled by the application using the database

## Representation

### Entities

#### schools

- `id`: `INT` with `AUTO_INCREMENT`, the primary key.
- `name`: `VARCHAR(32)` with `UNIQUE` and `NOT NULL`, so no two schools share a name and every school has one.

#### students

- `id`: `INT` primary key.
- `name`: `VARCHAR(32) NOT NULL`.
- `year`: `ENUM('S1', ..., 'S6') NOT NULL`. An `ENUM` restricts the value to the six valid year groups, which stops typos.
- `school_id`: `INT NOT NULL`, a foreign key to `schools(id)`. Every student must belong to a school.
- `gender`: `ENUM('male', 'female', 'other') NOT NULL`.
- `enrollment_date`: `DATE NOT NULL`.

#### teachers

- `id`: `INT` primary key.
- `name`: `VARCHAR(32) NOT NULL`.
- `department`: `VARCHAR(32)`, which is allowed to be `NULL` in case a teacher has no department.

#### subjects

- `id`: `INT` primary key.
- `name`: `VARCHAR(32) UNIQUE NOT NULL`, so each subject appears once.
- `department`: `VARCHAR(32)`, optional.

#### enrollments

- `id`: `INT` primary key.
- `student_id`, `subject_id`, `teacher_id`: `INT NOT NULL` foreign keys to `students`, `subjects` and `teachers`. This table records which teacher taught a student a particular subject.
- `year`: `YEAR NOT NULL`, the calendar year of the enrollment. `YEAR` is a compact type designed for exactly this.
- A `UNIQUE` key on (`student_id`, `subject_id`, `year`) stops a student being enrolled in the same subject twice in the same year.
- All three foreign keys use `ON DELETE CASCADE`, so removing a student, subject or teacher also removes the enrollments that depend on them.

#### assessments

- `id`: `INT` primary key.
- `subject_id`: `INT NOT NULL`, foreign key to `subjects(id)`.
- `name`: `VARCHAR(22) NOT NULL`, e.g. "Math Test 1".
- `date`: `DATE NOT NULL`.

#### scores

- `id`: `INT` primary key.
- `student_id`, `assessment_id`: `INT NOT NULL` foreign keys.
- `percentage`: `TINYINT NOT NULL` with `CHECK(percentage >= 0 AND percentage <= 100)`. A percentage never needs more than a `TINYINT`, and the `CHECK` stops impossible values.

#### study_sessions

- `id`: `INT` primary key.
- `student_id`, `subject_id`: `INT NOT NULL` foreign keys.
- `duration`: `INT NOT NULL`, in minutes. Minutes avoid decimals and are easy to average.
- `date`: `DATE NOT NULL`.

#### attendance

- `id`: `INT` primary key.
- `student_id`, `subject_id`: `INT NOT NULL` foreign keys.
- `status`: `ENUM('absent', 'late', 'present') NOT NULL`. There are only three valid states, so an `ENUM` fits.
- `date`: `DATE NOT NULL`.
- A `UNIQUE` key on (`student_id`, `subject_id`, `date`) stops two attendance records for the same student, subject and day.

#### wellbeing_surveys

- `id`: `INT` primary key.
- `student_id`: `INT NOT NULL`, foreign key to `students(id)`.
- `sleep_hours`: `TINYINT NOT NULL`, since hours of sleep are small whole numbers.
- `stress_level`: `TINYINT NOT NULL` with `CHECK(stress_level >= 1 AND stress_level <= 10)`, a 1 to 10 scale.
- `mood`: `VARCHAR(22) NOT NULL`, a short word such as "sleepy".
- `date`: `DATE NOT NULL`.

#### resources

- `id`: `INT` primary key.
- `student_id`: `INT NOT NULL`, the student who shared it.
- `subject_id`: `INT NOT NULL`, the subject it helps with.
- `type`: `VARCHAR(22) NOT NULL`, e.g. "website".
- `url`: `VARCHAR(255) NOT NULL`, long enough for most web addresses.
- `date`: `DATE NOT NULL`.

#### likes

- `id`: `INT` primary key.
- `student_id`, `resource_id`: `INT NOT NULL` foreign keys.
- A `UNIQUE` key on (`student_id`, `resource_id`) stops a student liking the same resource more than once.

Across the schema, `NOT NULL` is used wherever a record would be meaningless without the value, and foreign keys use `ON DELETE CASCADE` so that dependent records never point at something that no longer exists.

### Relationships

![ER diagram](image.png)

- A school has many students, but each student belongs to exactly one school.
- `enrollments` is a junction table. It makes the relationship between students and subjects many-to-many, and it also records which teacher was involved.
- A subject has many assessments, and each assessment produces many scores (one per student).
- A student can have many study sessions, attendance records and wellbeing surveys. Study sessions and attendance are also tied to a subject.
- A student can share many resources, and each resource belongs to one subject.
- `likes` is a junction table between students and resources, so a student can like many resources and a resource can be liked by many students.

## Optimizations

### Indexes

- Indexes on the foreign key columns used in joins: `subject_id` and `teacher_id` on `enrollments`; `student_id` and `assessment_id` on `scores`; `student_id` and `subject_id` on `study_sessions`; `subject_id` on `attendance`; `student_id` on `wellbeing_surveys`; and `student_id` and `subject_id` on `resources`. These columns appear in nearly every `JOIN` in the views and queries, so indexing them speeds up joins and lookups.
- Indexes on `students(name)` and `teachers(name)`, because the insert queries look people up by name.
- An index on `teachers(department)`, for finding teachers by department.
- Indexes on `wellbeing_surveys(sleep_hours)` and `wellbeing_surveys(stress_level)`, since the `support` view aggregates these.
- An index on `resources(type)`, for filtering by kind of resource.
- Some indexes come for free from `UNIQUE` constraints: `schools(name)`, `subjects(name)`, and the combined keys on `enrollments`, `attendance` and `likes`. Because those combined keys start with `student_id`, I did not add a separate `student_id` index on those three tables.
- I skipped `assessments` since it is small and only accessed through its foreign key, which the database indexes automatically.

### Views

- `number_of_users`: a simple count of students.
- `popular_subjects`: the ten subjects with the most enrolled students.
- `relationship_attendance`: each student's average score next to how often they were present, to see whether attendance and results are linked.
- `relationship_study`: each student's average score next to their average study time.
- `support`: per student, their name, school, average score, attendance, average sleep and average stress, ordered so those with the lowest attendance, scores and sleep and the highest stress come first. It is meant to help staff spot students who might need support.
- `useful_resources`: the 25 most-liked resources.

The three views that combine several tables (`relationship_attendance`, `relationship_study` and `support`) total each table separately in a subquery before joining them. Joining the tables directly would pair every score with every attendance record for the same student, which would inflate the totals and skew the averages.

Views save writing long, repeated joins and give the people reading the data a simple name to query.

## Limitations

- Names as identifiers. Several queries find students, teachers and subjects by name. If two students share a name, those queries would match both.
- Teachers are not linked to schools, and subjects are shared by every school, so the database cannot say which school a teacher works at or which school offers which subject.
- Limited uniqueness checks. Enrollments, attendance and likes cannot be duplicated, but nothing stops the same score or wellbeing survey being entered twice.
- Coarse attendance. Attendance is one record per subject per date, so it cannot represent several lessons of one subject in a day or a particular period.
- Simple wellbeing data. Sleep is stored in whole hours and mood is free text, so moods like "tired" and "sleepy" are counted separately.
- Views are limited. The two `relationship` views only show the top 100 students, and the correlation they show does not prove one thing causes another. The `support` view only includes students who have at least one score, attendance record and wellbeing survey, so a student with no survey data would not appear.
- Sensitive data. Wellbeing and attendance records are personal. The database has no concept of users or permissions, so protecting that data would have to be done by the application on top of it.
