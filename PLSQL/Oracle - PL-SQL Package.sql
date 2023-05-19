
CREATE OR REPLACE PACKAGE course_management AS
  PROCEDURE show_students (p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_courses(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_prerequisites(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_course_credit(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_classes(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_score_grade(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_g_enrollments(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_logs(p_cursor OUT SYS_REFCURSOR);
  PROCEDURE show_students_in_class(p_classid IN classes.classid%TYPE, p_students OUT SYS_REFCURSOR);
  PROCEDURE get_all_prerequisites(p_dept_code IN VARCHAR2, p_course_num IN NUMBER,p_cur OUT SYS_REFCURSOR);
  -- PROCEDURE get_all_prerequisites (p_dept_code IN VARCHAR2, p_course_num IN NUMBER,p_cursor OUT SYS_REFCURSOR);
  PROCEDURE enroll_student(p_B# IN students.B#%TYPE, p_classid IN classes.classid%TYPE);
  PROCEDURE DROP_GRAD_STUDENT_FROM_CLASS(p_B# IN students.B#%TYPE, p_classid IN classes.classid%TYPE);
  PROCEDURE delete_student(p_B# IN students.B#%TYPE);
END;
/

CREATE OR REPLACE PACKAGE BODY course_management AS


   PROCEDURE show_students (p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
OPEN p_cursor FOR
SELECT * FROM students;
END;

    PROCEDURE show_courses(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM courses;
END;


    PROCEDURE show_prerequisites(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM prerequisites;
END;


    PROCEDURE show_course_credit(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM course_credit;
END;


    PROCEDURE show_classes(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM classes;
END;
 

    PROCEDURE show_score_grade(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM score_grade;
END;


    PROCEDURE show_g_enrollments(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM g_enrollments;
END;


    PROCEDURE show_logs(p_cursor OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_cursor FOR SELECT * FROM logs;
END;


    PROCEDURE show_students_in_class(p_classid IN classes.classid%TYPE, p_students OUT SYS_REFCURSOR ) IS
      invalid_class EXCEPTION;
      -- PRAGMA EXCEPTION_INIT(invalid_class, -20000);
      class_count INTEGER;
  BEGIN
      SELECT COUNT(*) INTO class_count FROM classes WHERE classid = p_classid;
      IF class_count = 0 THEN
          RAISE invalid_class;
      END IF;
      OPEN p_students FOR
          SELECT s.B#, s.first_name, s.last_name
          FROM students s
          INNER JOIN g_enrollments e ON s.B# = e.g_B#
          WHERE e.classid = p_classid;      
  EXCEPTION
      WHEN invalid_class THEN
          RAISE_APPLICATION_ERROR(-20000, 'Invalid classid ' || p_classid);
          -- dbms_output.put_line('Error: invalid classid ' || p_classid);      
  END;


  PROCEDURE get_all_prerequisites(
      p_dept_code IN VARCHAR2,
      p_course_num IN NUMBER,
      p_cur OUT SYS_REFCURSOR
  ) IS
      v_prereq_dept_code VARCHAR2(4);
      v_prereq_course_num NUMBER;
  BEGIN
      -- check if the given course exists
      SELECT dept_code, course#
      INTO v_prereq_dept_code, v_prereq_course_num
      FROM courses
      WHERE dept_code = p_dept_code AND course# = p_course_num;
      
      
      -- get all direct prerequisites and add to temp table
      INSERT INTO temp_prerequisites(dept_code, course#)
      SELECT pre_dept_code, pre_course#
      FROM prerequisites
      WHERE dept_code = p_dept_code AND course# = p_course_num;
      
      -- recursively get indirect prerequisites and add to temp table
      FOR prereq IN (
          SELECT pre_dept_code, pre_course#
          FROM prerequisites
          WHERE dept_code = p_dept_code AND course# = p_course_num
      ) LOOP
          get_all_prerequisites(prereq.pre_dept_code, prereq.pre_course#, p_cur);
          INSERT INTO temp_prerequisites(dept_code, course#)
          SELECT pre_dept_code, pre_course#
          FROM prerequisites
          WHERE dept_code = prereq.pre_dept_code AND course# = prereq.pre_course#;
      END LOOP;
      
      -- return the data from temp table
      OPEN p_cur FOR
      SELECT DISTINCT dept_code, course#
      FROM temp_prerequisites;
      
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20002, p_dept_code || p_course_num || ' does not exist.');
              RETURN;

  END;




PROCEDURE enroll_student(p_B# IN students.B#%TYPE, p_classid IN classes.classid%TYPE) IS
    v_st_level students.st_level%TYPE;
    v_semester classes.semester%TYPE;
    v_year classes.year%TYPE;
    v_enroll_count number(1);
    v_B# students.B#%TYPE;
    v_class_limit classes.limit%TYPE;
    v_enroll_dept courses.dept_code%TYPE;
    v_enroll_course courses.course#%TYPE;
    C_grade_score score_grade.score%TYPE;
    v_prereq_count number(1);
    v_class_current_size classes.class_size%TYPE;
    v_prereq_enroll_count number(1);
BEGIN
    -- Check if B# is valid
    BEGIN
        SELECT B# INTO v_B# FROM students WHERE B# = p_B#;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'The Bid is invalid.');
    END;


    -- Check if B# is valid and belongs to a graduate student
    SELECT st_level INTO v_st_level FROM students WHERE B# = p_B#;
    IF v_st_level <> 'PhD' AND v_st_level <> 'master' THEN
        RAISE_APPLICATION_ERROR(-20002, 'This is not a graduate student.');
    END IF;
    
    -- Check if classid is valid
    BEGIN
        SELECT semester, year INTO v_semester, v_year FROM classes WHERE classid = p_classid;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'The classid is invalid.');
    END;
    
    -- Check if student is enrolled in the class
    SELECT COUNT(*) INTO v_enroll_count FROM g_enrollments WHERE g_B# = p_B# AND classid = p_classid;
    IF v_enroll_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'The student is already in the class.');
    END IF;
    
    -- Check if the class is offered in Spring 2021
    IF v_semester <> 'Spring' OR v_year <> 2021 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Cannot enroll into a class from a previous semester.');
    END IF;
    
    -- Check if the student has reached enrollment limit
    SELECT COUNT(*) INTO v_enroll_count FROM g_enrollments e 
        JOIN classes c ON e.classid = c.classid 
        WHERE e.g_B# = p_B# AND c.semester = 'Spring' AND c.year = 2021;
    IF v_enroll_count = 5 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Students cannot be enrolled in more than five classes in the same semester');
    END IF;

    -- Check if the class is already full
    SELECT class_size into v_class_current_size from classes where classid = p_classid;

    SELECT limit INTO v_class_limit 
    FROM classes 
    WHERE classid = p_classid;

      IF v_enroll_count >= v_class_limit THEN
          RAISE_APPLICATION_ERROR(-20007, 'This class is already full');
      END IF;


      --check prerequiaites
      SELECT dept_code, course# INTO v_enroll_dept, v_enroll_course 
      FROM classes 
      WHERE classid = p_classid;

      SELECT COUNT(*) INTO v_prereq_count 
      FROM prerequisites
      WHERE dept_code = v_enroll_dept 
      AND course# = v_enroll_course; 

      SELECT score INTO C_grade_score
      FROM score_grade 
      WHERE lgrade = 'C';

      SELECT COUNT(*) INTO v_prereq_enroll_count
      FROM classes cl 
      INNER JOIN prerequisites prereq 
      ON cl.dept_code = prereq.pre_dept_code AND cl.course# = prereq.pre_course#
      INNER JOIN g_enrollments ge
      ON ge.classid = cl.classid 
      WHERE CONCAT(cl.semester,cl.year) <> CONCAT(v_semester,v_year)
      AND ge.g_B# = p_B# 
      AND ge.score >= C_grade_score 
      AND prereq.dept_code = v_enroll_dept 
      AND prereq.course# = v_enroll_course;

      IF v_prereq_count <> v_prereq_enroll_count THEN
        RAISE_APPLICATION_ERROR(-20008, 'Prerequisites not satisfied');
      END IF;


    
    -- All checks passed, make the enrollment
    INSERT INTO g_enrollments(g_B#,classid) VALUES (p_B#, p_classid);
    DBMS_OUTPUT.PUT_LINE('Enrollment completed successfully.');
END enroll_student;


    PROCEDURE DROP_GRAD_STUDENT_FROM_CLASS (
      p_B# IN students.B#%TYPE,
      p_classid IN classes.classid%TYPE
) IS
    v_st_level students.st_level%TYPE;
    v_semester classes.semester%TYPE;
    v_year classes.year%TYPE;
    v_enroll_count NUMBER(1);
    v_B# students.B#%TYPE;

    -- Exceptions
    invalid_bid EXCEPTION;
    not_grad_student EXCEPTION;
    invalid_classid EXCEPTION;
    not_enrolled EXCEPTION;
    not_current_semester EXCEPTION;
    last_class EXCEPTION;
BEGIN
    -- Check if B# is valid
    BEGIN
        SELECT B# INTO v_B# FROM students WHERE B# = p_B#;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE invalid_bid;
    END;
    

    -- Check if B# is valid and belongs to a graduate student
    SELECT st_level INTO v_st_level FROM students WHERE B# = p_B#;
    IF v_st_level <> 'PhD' AND v_st_level <> 'master' THEN
        RAISE not_grad_student;
    END IF;

    -- Check if classid is valid
    BEGIN
        SELECT semester INTO v_semester FROM classes WHERE classid = p_classid;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE invalid_classid;
    END;

    -- Check if student is enrolled in the class
    SELECT COUNT(*) INTO v_enroll_count FROM g_enrollments WHERE g_B# = p_B# AND classid = p_classid;
    IF v_enroll_count = 0 THEN
        RAISE not_enrolled;
    END IF;

    -- Check if the class is offered in Spring 2021
    IF v_semester <> 'Spring' OR v_year <> 2021 THEN
        RAISE not_current_semester;
    END IF;

    -- Check if the class is the last class for the student in Spring 2021
    SELECT COUNT(*) INTO v_enroll_count FROM g_enrollments e 
        JOIN classes c ON e.classid = c.classid 
        WHERE e.g_B# = p_B# AND c.semester = 'Spring' AND c.year = 2021;
    IF v_enroll_count = 1 THEN
        RAISE last_class;
    END IF;

    -- All checks passed, delete the enrollment
    DELETE FROM g_enrollments WHERE g_B# = p_B# AND classid = p_classid;

    -- Print success message
    DBMS_OUTPUT.PUT_LINE('Enrollment dropped successfully.');

EXCEPTION
    WHEN invalid_bid THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid B#.');
    WHEN not_grad_student THEN
        RAISE_APPLICATION_ERROR(-20002, 'This is not a graduate student.');
    WHEN invalid_classid THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid classid.');
    WHEN not_enrolled THEN
        RAISE_APPLICATION_ERROR(-20004, 'The student is not enrolled in the class.');
    WHEN not_current_semester THEN
        RAISE_APPLICATION_ERROR(-20005, 'Only enrollment in the current semester can be dropped.');
    WHEN last_class THEN
        RAISE_APPLICATION_ERROR(-20006, 'This is the only class for this student in Spring 2021 and cannot be dropped.');
END DROP_GRAD_STUDENT_FROM_CLASS;




PROCEDURE delete_student(p_B# IN students.B#%TYPE) IS
  v_B# students.B#%TYPE;
BEGIN
  -- Check if B# is valid
  BEGIN
    SELECT B# INTO v_B# FROM students WHERE B# = p_B#;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('The B# is invalid.');
      RAISE_APPLICATION_ERROR(-20001, 'The Bid is invalid.');
    END;

  --  DELETE FROM g_enrollments 
  -- WHERE g_B# = p_B#;


  DELETE FROM students
  WHERE B# = p_B#;
  DBMS_OUTPUT.PUT_LINE('Student Deleted successfully.');

 END delete_student;

END;

/


