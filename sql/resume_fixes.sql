-- =====================================================================
-- SAMPLE27 - make the four resumes agree with EMPLOYEE (birth date, hire date) and be believable
-- Copyright (c) 2026 Marcin Paluch. All rights reserved.
--
-- The shipped resumes are about 30 years older than the EMPLOYEE rows (Quintana: born 1925 in the resume,
-- 1955 in EMPLOYEE; hired 1971 in the resume, 2001 in EMPLOYEE). Only dates inside the text change here.
-- The old-school layout stays as shipped: fixed-width columns in the ascii copy, <DT>/<DD> lists in the html copy.
--   1. Birthdate and Hire Date lines are copied from EMPLOYEE.
--   2. Education years and the three work-history ranges get a plausible timeline: the present job starts in the hire
--      month, the two earlier jobs end the month before the next one starts, degrees are earned at about 20-24.
--   3. The html copies also carry conversion and review dates (META tags, "converted ... on 16 Aug 2000"); these are
--      moved to just after the hire, with weekday names that match the calendar.
-- Walker (000190) was born 1982-06-25 and hired 2001-07-26, at 19. His degrees are dated 2004 and 2006 (earned while
-- working) and his earlier jobs are school-leaver jobs. That is the one resume that stays unusual; EMPLOYEE.HIREDATE is
-- the shipped value and is not changed for it.
-- Run once, after the data load (EMP_RESUME must still hold the shipped text). Not repeatable.
-- =====================================================================
CONNECT TO SAMPLE27;

-- 1. birth date and hire date from EMPLOYEE
UPDATE DB2INST1.EMP_RESUME R
   SET RESUME = (
     SELECT REGEXP_REPLACE(R.RESUME, '(Birthdate:\s+(<DD>)?)[A-Z][a-z]+ [0-9]{1,2}, [0-9]{4}',
              '\1' || RTRIM(MONTHNAME(E.BIRTHDATE)) || ' ' || RTRIM(CHAR(DAY(E.BIRTHDATE))) || ', ' || RTRIM(CHAR(YEAR(E.BIRTHDATE))))
     FROM DB2INST1.EMPLOYEE E WHERE E.EMPNO = R.EMPNO);

UPDATE DB2INST1.EMP_RESUME R
   SET RESUME = (
     SELECT REGEXP_REPLACE(R.RESUME, '(Hire Date:\s+(<DD>)?)[0-9]{4}-[0-9]{2}-[0-9]{2}', '\1' || CHAR(E.HIREDATE, ISO))
     FROM DB2INST1.EMPLOYEE E WHERE E.EMPNO = R.EMPNO);

-- 2. education years (newest first, as shipped): ascii "  1965" followed by blanks, html "<DT>1965"
UPDATE DB2INST1.EMP_RESUME R
   SET RESUME = (
     SELECT CASE R.RESUME_FORMAT
              WHEN 'ascii' THEN REPLACE(REPLACE(R.RESUME, '  ' || X.O1 || '  ', '  ' || X.N1 || '  '), '  ' || X.O2 || '  ', '  ' || X.N2 || '  ')
              ELSE              REPLACE(REPLACE(R.RESUME, '<DT>' || X.O1, '<DT>' || X.N1), '<DT>' || X.O2, '<DT>' || X.N2)
            END
     FROM (VALUES ('000130', '1965', '1979', '1960', '1975'),
                  ('000140', '1972', '2001', '1969', '1997'),
                  ('000150', '1971', '1999', '1968', '1998'),
                  ('000190', '1974', '2006', '1972', '2004')) X (EMPNO, O1, N1, O2, N2)
     WHERE X.EMPNO = R.EMPNO)
 WHERE R.EMPNO IN ('000130', '000140', '000150', '000190');

-- 3. work history, newest first: present job = hire month. The ascii range column is 20 characters wide.
UPDATE DB2INST1.EMP_RESUME R
   SET RESUME = (
     SELECT CASE R.RESUME_FORMAT
              WHEN 'ascii' THEN REPLACE(REPLACE(REPLACE(R.RESUME, RPAD(X.O1, 20), RPAD(X.N1, 20)), RPAD(X.O2, 20), RPAD(X.N2, 20)), RPAD(X.O3, 20), RPAD(X.N3, 20))
              ELSE              REPLACE(REPLACE(REPLACE(R.RESUME, '<DT>' || X.O1, '<DT>' || X.N1), '<DT>' || X.O2, '<DT>' || X.N2), '<DT>' || X.O3, '<DT>' || X.N3)
            END
     FROM (VALUES ('000130', '10/91 - present', '7/01 - present',  '12/85 - 9/91', '12/89 - 6/01', '1/79 - 11/85', '1/80 - 11/89'),
                  ('000140', '2/83 - present',  '12/01 - present', '12/76 - 1/83', '9/98 - 11/01', '9/72 - 11/76', '7/97 - 8/98'),
                  ('000150', '8/79 - present',  '2/01 - present',  '2/72 - 7/79',  '2/00 - 1/01',  '9/71 - 1/72',  '9/99 - 1/00'),
                  ('000190', '6/87 - present',  '7/01 - present',  '4/77 - 5/87',  '4/00 - 6/01',  '9/74 - 3/77',  '9/99 - 3/00'))
          X (EMPNO, O1, N1, O2, N2, O3, N3)
     WHERE X.EMPNO = R.EMPNO)
 WHERE R.EMPNO IN ('000130', '000140', '000150', '000190');

-- 4. html copies: conversion comment and the three META dates (updated / review / expires), keeping the time of day
UPDATE DB2INST1.EMP_RESUME R
   SET RESUME = (
     SELECT REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(R.RESUME,
              'on 16 Aug 2000 at', 'on ' || X.CONV || ' at'),
              '("updated" CONTENT=")[A-Za-z]{3}, [0-9]+ [A-Za-z]{3} [0-9]{4}', '\1' || X.UPD),
              '("review" CONTENT=")[A-Za-z]{3}, [0-9]+ [A-Za-z]{3} [0-9]{4}', '\1' || X.REV),
              '("expires" CONTENT=")[A-Za-z]{3}, [0-9]+ [A-Za-z]{3} [0-9]{4}', '\1' || X.EXP)
     FROM (VALUES
                  ('000130', 'Tue, 14 Aug 2001', 'Wed, 14 Aug 2002', 'Thu, 14 Aug 2003', '14 Aug 2001'),
                  ('000140', 'Thu, 3 Jan 2002', 'Fri, 3 Jan 2003', 'Mon, 5 Jan 2004', '3 Jan 2002'),
                  ('000150', 'Thu, 1 Mar 2001', 'Fri, 1 Mar 2002', 'Mon, 3 Mar 2003', '1 Mar 2001'),
                  ('000190', 'Mon, 13 Aug 2001', 'Tue, 13 Aug 2002', 'Wed, 13 Aug 2003', '13 Aug 2001')) X (EMPNO, UPD, REV, EXP, CONV)
     WHERE X.EMPNO = R.EMPNO)
 WHERE R.RESUME_FORMAT = 'html';

-- check: every resume carries the EMPLOYEE hire date and birth date (expect no rows)
SELECT 'RESUME_CHECK mismatch' AS C, R.EMPNO, R.RESUME_FORMAT
FROM   DB2INST1.EMP_RESUME R JOIN DB2INST1.EMPLOYEE E ON E.EMPNO = R.EMPNO
WHERE  LOCATE(CHAR(E.HIREDATE, ISO), R.RESUME) = 0
   OR  LOCATE(RTRIM(MONTHNAME(E.BIRTHDATE)) || ' ' || RTRIM(CHAR(DAY(E.BIRTHDATE))) || ', ' || RTRIM(CHAR(YEAR(E.BIRTHDATE))), R.RESUME) = 0;
COMMIT;
CONNECT RESET;
