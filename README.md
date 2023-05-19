# Student-Registration-System
The objective of this project is to develop an application using Oracle's PL/SQL and JDBC to
facilitate various student registration tasks in a university. The application will provide
functionalities such as adding and dropping courses, enrolling students in classes, and
managing student records.The application will be designed to handle a large amount of data,
including student records, course details, and enrollment information. PL/SQL will be used to
write the database stored procedures that will support these operations, while JDBC will be
used to communicate with the database and execute these stored procedures

In this project, as part of course_management package, the following procedures are
implemented:
### show_students: 
   This procedure returns a result set of all students in the database
### show_courses: 
   This procedure returns a result set of all courses in the database
### show_prerequisites: 
   This procedure returns a result set of all course prerequisites in the
database
### show_course_credit: 
   This procedure returns a result set of all courses and their credits in the database
### show_classes: 
   This procedure returns a result set of all classes in the database
### show_score_grade: 
   This procedure returns a result set of all student scores and grades in the database
### show_g_enrollments: 
   This procedure returns a result set of all graduate enrollments in the
database
### show_logs: 
   This procedure returns a result set of all log information in the database
### show_students_in_class: 
   This procedure takes a class ID as input and returns a result set of all students enrolled in that class
### get_all_prerequisites: 
   This procedure takes a department code and a course number as
inputs and returns a result set of all prerequisites for that course
### enroll_student: 
   This procedure takes a student ID and a class ID as inputs and enrolls the
    student in the specified class
### drop_graduate_student_from_class: 
   This procedure takes a student ID and a class ID as
    inputs and drops the specified graduate student from the specified class
### delete_student: 
   This procedure takes a student ID as input and deletes the student from the
    database
