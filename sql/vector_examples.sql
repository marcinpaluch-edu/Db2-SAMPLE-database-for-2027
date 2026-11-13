-- =====================================================================
-- SAMPLE27 - vector similarity examples (read-only)
--
-- Copyright (c) 2026 Marcin Paluch. All rights reserved.
--
-- Standalone: not part of build_sample27.sh and it changes nothing.
--   podman cp sql/vector_examples.sql <your_db2_container_name>:/tmp/
--   podman exec <your_db2_container_name> su - db2inst1 -c "db2 -tf /tmp/vector_examples.sql"
--
-- Tables used (all from the original SAMPLE, loaded unchanged):
--   PATIENTS           20 rows, EMBEDDING VECTOR(768,  FLOAT32)
--   MLBLOGS_QUESTIONS   5 rows, EMBEDDING VECTOR(1024, FLOAT32)
--   MLBLOGS_ANSWERS   108 rows, EMBEDDING VECTOR(1024, FLOAT32)
-- There is no vector index, so every query compares against every row.
-- Cosine distances in PATIENTS are tiny (all below 0.0004), so they are shown
-- multiplied by one million (DIST_E6).  Only the ranking is meaningful.
-- =====================================================================

CONNECT TO SAMPLE27;

-- 1. The five patients most similar to patient 6 (57, female, smoker, cholesterol 237, BP 155)
SELECT P.PATIENT_ID, P.AGE, P.GENDER, P.CHOLESTEROL_LEVEL, P.BLOOD_PRESSURE, P.SMOKING_STATUS,
       DEC(VECTOR_DISTANCE(P.EMBEDDING, T.EMBEDDING, COSINE) * 1000000, 8, 1) AS DIST_E6
FROM   DB2INST1.PATIENTS P
CROSS JOIN (SELECT EMBEDDING FROM DB2INST1.PATIENTS WHERE PATIENT_ID = 6) T
WHERE  P.PATIENT_ID <> 6
ORDER BY VECTOR_DISTANCE(P.EMBEDDING, T.EMBEDDING, COSINE)
FETCH FIRST 5 ROWS ONLY;

-- 2. Are similar patients similar?  Nearest and farthest neighbour of every patient,
--    against the average over all 380 pairs.
WITH D AS (
    SELECT A.PATIENT_ID AS AID, B.PATIENT_ID AS BID,
           VECTOR_DISTANCE(A.EMBEDDING, B.EMBEDDING, COSINE)             AS DIST,
           ABS(A.AGE - B.AGE)                                            AS DAGE,
           ABS(A.CHOLESTEROL_LEVEL - B.CHOLESTEROL_LEVEL)                AS DCHOL,
           ABS(A.BLOOD_PRESSURE - B.BLOOD_PRESSURE)                      AS DBP,
           CASE WHEN A.SMOKING_STATUS = B.SMOKING_STATUS THEN 1 ELSE 0 END AS SAMESMOKE,
           CASE WHEN A.GENDER = B.GENDER THEN 1 ELSE 0 END               AS SAMEGENDER
    FROM   DB2INST1.PATIENTS A
    JOIN   DB2INST1.PATIENTS B ON A.PATIENT_ID <> B.PATIENT_ID
),
R AS (
    SELECT D.*,
           ROW_NUMBER() OVER(PARTITION BY AID ORDER BY DIST)      AS RN_NEAR,
           ROW_NUMBER() OVER(PARTITION BY AID ORDER BY DIST DESC) AS RN_FAR
    FROM   D
)
SELECT 'nearest neighbour' AS PAIRS, COUNT(*) AS N,
       DEC(AVG(DOUBLE(DAGE)), 5, 1) AS AVG_AGE_GAP, DEC(AVG(DOUBLE(DCHOL)), 6, 1) AS AVG_CHOL_GAP,
       DEC(AVG(DOUBLE(DBP)), 5, 1) AS AVG_BP_GAP, DEC(AVG(DOUBLE(SAMESMOKE)), 4, 2) AS SAME_SMOKING,
       DEC(AVG(DOUBLE(SAMEGENDER)), 4, 2) AS SAME_GENDER
FROM   R WHERE RN_NEAR = 1
UNION ALL
SELECT 'farthest', COUNT(*), DEC(AVG(DOUBLE(DAGE)), 5, 1), DEC(AVG(DOUBLE(DCHOL)), 6, 1),
       DEC(AVG(DOUBLE(DBP)), 5, 1), DEC(AVG(DOUBLE(SAMESMOKE)), 4, 2), DEC(AVG(DOUBLE(SAMEGENDER)), 4, 2)
FROM   R WHERE RN_FAR = 1
UNION ALL
SELECT 'all pairs', COUNT(*), DEC(AVG(DOUBLE(DAGE)), 5, 1), DEC(AVG(DOUBLE(DCHOL)), 6, 1),
       DEC(AVG(DOUBLE(DBP)), 5, 1), DEC(AVG(DOUBLE(SAMESMOKE)), 4, 2), DEC(AVG(DOUBLE(SAMEGENDER)), 4, 2)
FROM   D;

-- 3. What do the embeddings follow most?  Average distance inside and between groups.
SELECT CASE WHEN A.SMOKING_STATUS = B.SMOKING_STATUS THEN 'same smoking status'
            ELSE 'different smoking status' END AS PAIRS,
       COUNT(*) AS N,
       DEC(AVG(VECTOR_DISTANCE(A.EMBEDDING, B.EMBEDDING, COSINE)) * 1000000, 8, 1) AS AVG_DIST_E6
FROM   DB2INST1.PATIENTS A
JOIN   DB2INST1.PATIENTS B ON A.PATIENT_ID <> B.PATIENT_ID
GROUP BY CASE WHEN A.SMOKING_STATUS = B.SMOKING_STATUS THEN 'same smoking status'
              ELSE 'different smoking status' END
UNION ALL
SELECT CASE WHEN A.GENDER = B.GENDER THEN 'same gender' ELSE 'different gender' END,
       COUNT(*),
       DEC(AVG(VECTOR_DISTANCE(A.EMBEDDING, B.EMBEDDING, COSINE)) * 1000000, 8, 1)
FROM   DB2INST1.PATIENTS A
JOIN   DB2INST1.PATIENTS B ON A.PATIENT_ID <> B.PATIENT_ID
GROUP BY CASE WHEN A.GENDER = B.GENDER THEN 'same gender' ELSE 'different gender' END;

-- 4. Question answering: the two closest blog passages for each question
SELECT Q.QUESTION_ID, SUBSTR(Q.QUESTION, 1, 55) AS QUESTION,
       A.ANSWER_ID, SUBSTR(REPLACE(A.ANSWER, CHR(10), ' '), 1, 60) AS ANSWER_START,
       DEC(A.DIST, 6, 4) AS DIST
FROM   DB2INST1.MLBLOGS_QUESTIONS Q
JOIN   LATERAL (SELECT X.ANSWER_ID, X.ANSWER,
                       VECTOR_DISTANCE(Q.EMBEDDING, X.EMBEDDING, COSINE) AS DIST
                FROM   DB2INST1.MLBLOGS_ANSWERS X
                ORDER BY VECTOR_DISTANCE(Q.EMBEDDING, X.EMBEDDING, COSINE)
                FETCH FIRST 2 ROWS ONLY) A ON 1 = 1
ORDER BY Q.QUESTION_ID, A.DIST;

CONNECT RESET;
