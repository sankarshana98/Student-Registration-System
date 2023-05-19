-- Sequence to generate log# values in logs table
CREATE SEQUENCE logs_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;