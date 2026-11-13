-- =====================================================================
-- SAMPLE27 - data fixes : keep the original dates, repair only the impossible ones
--
-- Copyright (c) 2026 Marcin Paluch. All rights reserved.
--
-- Run after sample27.ddl and the data load (build_sample27.sh does this).
--
-- Rules
--   * The original dates stay as they are: hire 1977-2006, sales 1996-2006, orders 2004-2006,
--     promotions 2004-2006, projects 2002-2003, mail December 1988.  Nothing is shifted.
--     (SAMPLE26 moved them forward; SAMPLE27 does not.)
--   * Only combinations that cannot be true are repaired, with the smallest change:
--       1. Three projects (MA2111, MA2112, MA2113) end in 1982, twenty years before they
--          start in 2002: the end date gets +20 years (typo, 2002-12-01).
--       2. 15 people have an assignment that starts before their hire date (35 of 73
--          assignments).  The HIRE date moves back by whole years, just enough to be on or
--          before the first assignment (one statement, 15 rows).  The month and day are kept.
--          Moving the assignments instead would touch 35 rows plus the project and activity
--          dates that other tables depend on.
--       3. Four people were born in 2002-2003, i.e. hired as children or before they were
--          born (JONES, PULASKI, MARINO, PEREZ).  A 30-year typo is assumed: birth year -30
--          (2003 -> 1973).  Month and day are kept.
--       4. Anybody still under 18 at hire (JEFFERSON, PARKER) gets the birth date moved back
--          by the whole years needed to be 18 on the hire date.
--   * Stays as it was, on purpose, as a finding: the resume text (CLOB) disagrees with the
--     EMPLOYEE row by 30 years (born 1925 vs 1955), hire dates of the mail senders are years
--     after the mail.
--   * Project work outside the project dates (13 rows) is repaired by widening the project.
--   * Type change for modern salaries: STAFF.SALARY and STAFF.COMM are DECIMAL(9,2) (original
--     DECIMAL(7,2), max 99,999.99), the same as EMPLOYEE.SALARY.  The change is in ddl/sample27.ddl.
--     Values, views, triggers and the sample programs are unaffected (checked on the original).
-- =====================================================================

CONNECT TO SAMPLE27;

-- 1. projects that end 20 years before they start
UPDATE DB2INST1.PROJECT
   SET PRENDATE = PRENDATE + 20 YEARS
 WHERE PRENDATE < PRSTDATE;

-- 2. assignment before hire: move the hire date back by whole years, just enough
UPDATE DB2INST1.EMPLOYEE E
   SET HIREDATE = HIREDATE - ((YEAR(HIREDATE) - (SELECT YEAR(MIN(P.EMSTDATE)) FROM DB2INST1.EMPPROJACT P WHERE P.EMPNO = E.EMPNO))
                              + CASE WHEN MONTH(HIREDATE) * 100 + DAY(HIREDATE)
                                         > (SELECT MONTH(MIN(P.EMSTDATE)) * 100 + DAY(MIN(P.EMSTDATE)) FROM DB2INST1.EMPPROJACT P WHERE P.EMPNO = E.EMPNO)
                                     THEN 1 ELSE 0 END) YEARS
 WHERE HIREDATE > (SELECT MIN(P.EMSTDATE) FROM DB2INST1.EMPPROJACT P WHERE P.EMPNO = E.EMPNO);

-- 3. born in 2002-2003: a 30-year typo
UPDATE DB2INST1.EMPLOYEE
   SET BIRTHDATE = BIRTHDATE - 30 YEARS
 WHERE YEAR(BIRTHDATE) >= 2002;

-- 4. still under 18 at hire: birth date back by the whole years needed
UPDATE DB2INST1.EMPLOYEE
   SET BIRTHDATE = BIRTHDATE - ((YEAR(BIRTHDATE) + 18 - YEAR(HIREDATE))
                                + CASE WHEN MONTH(BIRTHDATE) * 100 + DAY(BIRTHDATE) > MONTH(HIREDATE) * 100 + DAY(HIREDATE)
                                       THEN 1 ELSE 0 END) YEARS
 WHERE HIREDATE < BIRTHDATE + 18 YEARS;

-- project date ranges: the ORIGINAL sample already has work outside its project dates
-- (11 EMPPROJACT rows end after the project, 1 starts before it, 1 PROJACT row lies outside).
-- The project is widened to cover its activities and assignments; people's own dates are not
-- touched.  Then each parent project is widened to cover its sub-projects (hierarchy has 3
-- levels at most, so two passes are enough).
UPDATE DB2INST1.PROJECT P
   SET PRENDATE = GREATEST(P.PRENDATE,
                           COALESCE((SELECT MAX(A.ACSTDATE) FROM DB2INST1.PROJACT A WHERE A.PROJNO = P.PROJNO), P.PRENDATE),
                           COALESCE((SELECT MAX(A.ACENDATE) FROM DB2INST1.PROJACT A WHERE A.PROJNO = P.PROJNO), P.PRENDATE),
                           COALESCE((SELECT MAX(E.EMSTDATE) FROM DB2INST1.EMPPROJACT E WHERE E.PROJNO = P.PROJNO), P.PRENDATE),
                           COALESCE((SELECT MAX(E.EMENDATE) FROM DB2INST1.EMPPROJACT E WHERE E.PROJNO = P.PROJNO), P.PRENDATE)),
       PRSTDATE = LEAST(P.PRSTDATE,
                        COALESCE((SELECT MIN(A.ACSTDATE) FROM DB2INST1.PROJACT A WHERE A.PROJNO = P.PROJNO), P.PRSTDATE),
                        COALESCE((SELECT MIN(E.EMSTDATE) FROM DB2INST1.EMPPROJACT E WHERE E.PROJNO = P.PROJNO), P.PRSTDATE))
 WHERE P.PRENDATE IS NOT NULL AND P.PRSTDATE IS NOT NULL;
UPDATE DB2INST1.PROJECT P
   SET PRENDATE = GREATEST(P.PRENDATE, COALESCE((SELECT MAX(C.PRENDATE) FROM DB2INST1.PROJECT C WHERE C.MAJPROJ = P.PROJNO), P.PRENDATE)),
       PRSTDATE = LEAST(P.PRSTDATE,    COALESCE((SELECT MIN(C.PRSTDATE) FROM DB2INST1.PROJECT C WHERE C.MAJPROJ = P.PROJNO), P.PRSTDATE))
 WHERE P.PRENDATE IS NOT NULL AND P.PRSTDATE IS NOT NULL;
UPDATE DB2INST1.PROJECT P
   SET PRENDATE = GREATEST(P.PRENDATE, COALESCE((SELECT MAX(C.PRENDATE) FROM DB2INST1.PROJECT C WHERE C.MAJPROJ = P.PROJNO), P.PRENDATE)),
       PRSTDATE = LEAST(P.PRSTDATE,    COALESCE((SELECT MIN(C.PRSTDATE) FROM DB2INST1.PROJECT C WHERE C.MAJPROJ = P.PROJNO), P.PRSTDATE))
 WHERE P.PRENDATE IS NOT NULL AND P.PRSTDATE IS NOT NULL;

-- date-range checks (these validate the data above)
ALTER TABLE DB2INST1.PROJECT ADD CONSTRAINT CK_PROJECT_DATES
  CHECK (PRENDATE IS NULL OR PRSTDATE IS NULL OR PRENDATE >= PRSTDATE) ENFORCED ENABLE QUERY OPTIMIZATION;
ALTER TABLE DB2INST1.PROJACT ADD CONSTRAINT CK_PROJACT_DATES
  CHECK (ACENDATE IS NULL OR ACENDATE >= ACSTDATE) ENFORCED ENABLE QUERY OPTIMIZATION;
ALTER TABLE DB2INST1.EMPPROJACT ADD CONSTRAINT CK_EMPPROJACT_DATES
  CHECK (EMENDATE IS NULL OR EMENDATE >= EMSTDATE) ENFORCED ENABLE QUERY OPTIMIZATION;
ALTER TABLE DB2INST1.PRODUCT ADD CONSTRAINT CK_PRODUCT_PROMO
  CHECK (PROMOEND IS NULL OR PROMOSTART IS NULL OR PROMOEND >= PROMOSTART) ENFORCED ENABLE QUERY OPTIMIZATION;

REFRESH TABLE DB2INST1.ADEFUSR;
COMMIT;

CONNECT RESET;
