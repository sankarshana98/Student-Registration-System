drop table g_enrollments;
drop table score_grade;
drop table classes;
drop table course_credit;
drop table prerequisites;
drop table courses;
drop table students;
drop table logs;

create table students (B# char(9) primary key check (B# like 'B%'),
first_name varchar2(15) not null, last_name varchar2(15) not null, st_level varchar2(10) 
check (st_level in ('freshman', 'sophomore', 'junior', 'senior', 'master', 'PhD')), 
gpa number(3,2) check (gpa between 0 and 4.0), email varchar2(20) unique,
bdate date);

create table courses (dept_code varchar2(4), course# number(3)
check (course# between 100 and 799), title varchar2(20) not null,
primary key (dept_code, course#));

create table prerequisites (dept_code varchar2(4) not null,
course# number(3) not null, pre_dept_code varchar2(4) not null,
pre_course# number(3) not null,
primary key (dept_code, course#, pre_dept_code, pre_course#),
foreign key (dept_code, course#) references courses on delete cascade,
foreign key (pre_dept_code, pre_course#) references courses on delete cascade);

create table course_credit (course# number(3) primary key,
check (course# between 100 and 799), credits number(1) check (credits in (3, 4)),
check ((course# < 500 and credits = 4) or (course# >= 500 and credits = 3)));

create table classes (classid char(5) primary key check (classid like 'c%'), 
dept_code varchar2(4) , course# number(3), 
sect# number(2), year number(4), semester varchar2(8) 
check (semester in ('Spring', 'Fall', 'Summer 1', 'Summer 2', 'Winter')), 
limit number(3), class_size number(3), room varchar2(10), 
foreign key (dept_code, course#) references courses on delete cascade, 
unique(dept_code, course#, sect#, year, semester), check (class_size <= limit),
check ((class_size >= 6 and course# >= 500) or class_size >= 10));

create table score_grade (score number(4, 2) primary key,
lgrade varchar2(2) check (lgrade in ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-','D', 'F', 'I')));

create table g_enrollments (g_B# char(9) references students, classid char(5) references classes, 
score number(4, 2) references score_grade, primary key (g_B#, classid));

create table logs (log# number(4) primary key, 
user_name varchar2(10) not null, 
op_time date not null, 
table_name varchar2(13) not null, 
operation varchar2(6) not null, 
tuple_keyvalue varchar2(20));

-- CREATE GLOBAL TEMPORARY TABLE temp_prerequisites(
--     dept_code VARCHAR2(4),
--     course# NUMBER
-- ) ON COMMIT DELETE ROWS; -- Uncomment this part of the query when running the script forthe first time and comment it back! 
/
