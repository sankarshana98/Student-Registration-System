-- Trigger to add a tuple to the Logs table when a student is successfully deleted from students table
CREATE OR REPLACE TRIGGER student_deleted
AFTER DELETE ON students
FOR EACH ROW
BEGIN
  INSERT INTO logs(log#, user_name, op_time, table_name, operation, tuple_keyvalue) 
  VALUES(logs_seq.NEXTVAL, USER , SYSDATE, 'STUDENTS', 'DELETE', :OLD.B#);
END;
/


-- Trigger to add a tuple to the Logs table when a student is successfully enrolled into a class in the G_Enrollments table
CREATE OR REPLACE TRIGGER TRG_G_ENROLLMENTS_INSERT
AFTER INSERT ON G_ENROLLMENTS
FOR EACH ROW
DECLARE
  v_tuple_keyvalue VARCHAR2(20);
BEGIN
  v_tuple_keyvalue := :new.g_B# || ',' || :new.classid;
  INSERT INTO logs(log#, user_name, op_time, table_name, operation, tuple_keyvalue)
  VALUES(logs_seq.NEXTVAL, USER, SYSDATE, 'G_ENROLLMENTS', 'INSERT', v_tuple_keyvalue);
END;
/

-- Trigger to add a tuple to the Logs table when a student is successfully deleted from a class in the G_Enrollments table
CREATE OR REPLACE TRIGGER trg_g_enrollments_delete
AFTER DELETE ON g_enrollments
FOR EACH ROW
BEGIN
  INSERT INTO logs(log#, user_name, op_time, table_name, operation, tuple_keyvalue)
  VALUES(logs_seq.NEXTVAL, USER, SYSDATE, 'g_enrollments', 'DELETE', (:OLD.g_B# || ',' || :OLD.classid));
END;
/

-- Trigger to delete all the records from G_ENROLLMENTS before records are deleted froms STUDENTS table to maintain Integrity
CREATE OR REPLACE TRIGGER trg_delete_student_enrollments
BEFORE DELETE ON students
FOR EACH ROW
BEGIN
  DELETE FROM g_enrollments WHERE g_B# = :OLD.B#;
END;
/

-- Trigger to update class size when a student is deleted from G_ENROLLMENTS
CREATE OR REPLACE TRIGGER update_class_size_on_classdrop
AFTER DELETE ON g_enrollments
FOR EACH ROW
DECLARE
    v_class_size INTEGER;
BEGIN
    -- get the current size of the class
    SELECT class_size INTO v_class_size FROM classes WHERE classid = :OLD.classid;
   
    -- update the class size in the classes table
    UPDATE classes SET class_size = v_class_size - 1 WHERE classid = :OLD.classid;
END;
/

-- Trigger to update class size when a student is added into G_ENROLLMENTS
CREATE OR REPLACE TRIGGER update_class_size_on_enrollment
AFTER INSERT ON g_enrollments
FOR EACH ROW
DECLARE
    v_class_size INTEGER;
BEGIN
    -- get the current size of the class
    SELECT class_size INTO v_class_size FROM classes WHERE classid = :NEW.classid;

    -- update the class size in the classes table
    UPDATE classes SET class_size = v_class_size + 1 WHERE classid = :NEW.classid;
END;
/

