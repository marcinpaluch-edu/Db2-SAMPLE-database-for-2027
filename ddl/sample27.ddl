-- =====================================================================
-- SAMPLE27 - modernized IBM Db2 SAMPLE database : schema DDL
--
-- Copyright (c) 2026 Marcin Paluch. All rights reserved.
--
-- Derived from the IBM Db2 SAMPLE database (db2look, Db2 12.1.5.0 LUW).
-- Target : IBM Db2 12.1 LUW, database SAMPLE27 (created by build_sample27.sh)
-- Order  : tablespaces, schema, tables, keys, indexes, aliases, views,
--          routines, triggers.  Data is loaded afterwards; see
--          ../sql/data_fixes.sql for the 2026 date refresh and data repairs.
-- =====================================================================

CONNECT TO SAMPLE27;

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

------------------------------------------------
-- DDL Statements for Tablespaces
-- (used by the tables below; not part of the original script)
------------------------------------------------

CREATE LARGE TABLESPACE "IBMDB2SAMPLEREL" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
	PAGESIZE 8192 MANAGED BY AUTOMATIC STORAGE
	AUTORESIZE YES INITIALSIZE 32 M MAXSIZE NONE
	EXTENTSIZE 32 PREFETCHSIZE AUTOMATIC BUFFERPOOL "IBMDEFAULTBP";

CREATE LARGE TABLESPACE "IBMDB2SAMPLEXML" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
	PAGESIZE 8192 MANAGED BY AUTOMATIC STORAGE
	AUTORESIZE YES INITIALSIZE 32 M MAXSIZE NONE
	EXTENTSIZE 32 PREFETCHSIZE AUTOMATIC BUFFERPOOL "IBMDEFAULTBP";

CREATE LARGE TABLESPACE "IBMDB2SAMPLEVECTOR" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
	PAGESIZE 8192 MANAGED BY AUTOMATIC STORAGE
	AUTORESIZE YES INITIALSIZE 32 M MAXSIZE NONE
	EXTENTSIZE 32 PREFETCHSIZE AUTOMATIC BUFFERPOOL "IBMDEFAULTBP";

------------------------------------------------
-- DDL Statements for Schemas
------------------------------------------------

-- Running the DDL below will explicitly create a schema in the
-- new database that corresponds to an implicitly created schema
-- in the original database.

CREATE SCHEMA "DB2INST1";

COMMENT ON SCHEMA "DB2INST1" IS 'SAMPLE27 - Copyright (c) 2026 Marcin Paluch. All rights reserved.';


---------------------------------
-- DDL Statements for Sequences
---------------------------------


-- SAMPLE27: used for PURCHASEORDER.POID.  The original started at 1; the loaded orders are 5000-5006,
-- so the sequence starts at 5007 (the next free POID).
CREATE SEQUENCE "DB2INST1"."SAMPSEQUENCE" AS BIGINT
	MINVALUE 1 MAXVALUE 9223372036854775807
	START WITH 5007 INCREMENT BY 1
	CACHE 20 NO CYCLE NO ORDER;



------------------------------------------------
-- DDL Statements for Table "DB2INST1"."CL_SCHED"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."CL_SCHED"  (
		  "CLASS_CODE" CHAR(7 OCTETS) NOT NULL , 
		  "DAY" SMALLINT NOT NULL , 
		  "STARTING" TIME NOT NULL , 
		  "ENDING" TIME )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."CL_SCHED"
-- (added in SAMPLE27; key columns made NOT NULL)

ALTER TABLE "DB2INST1"."CL_SCHED"
	ADD CONSTRAINT "PK_CL_SCHED" PRIMARY KEY
		("CLASS_CODE",
		 "DAY",
		 "STARTING")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."DEPARTMENT"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."DEPARTMENT"  (
		  "DEPTNO" CHAR(3 OCTETS) NOT NULL , 
		  "DEPTNAME" VARCHAR(36 OCTETS) NOT NULL , 
		  "MGRNO" CHAR(6 OCTETS) , 
		  "ADMRDEPT" CHAR(3 OCTETS) NOT NULL , 
		  "LOCATION" CHAR(16 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."DEPARTMENT"

ALTER TABLE "DB2INST1"."DEPARTMENT" 
	ADD CONSTRAINT "PK_DEPARTMENT" PRIMARY KEY
		("DEPTNO")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."DEPARTMENT"

CREATE INDEX "DB2INST1"."XDEPT2" ON "DB2INST1"."DEPARTMENT" 
		("MGRNO" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."DEPARTMENT"

CREATE INDEX "DB2INST1"."XDEPT3" ON "DB2INST1"."DEPARTMENT" 
		("ADMRDEPT" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."EMPLOYEE"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."EMPLOYEE"  (
		  "EMPNO" CHAR(6 OCTETS) NOT NULL , 
		  "FIRSTNME" VARCHAR(12 OCTETS) NOT NULL , 
		  "MIDINIT" CHAR(1 OCTETS) , 
		  "LASTNAME" VARCHAR(15 OCTETS) NOT NULL , 
		  "WORKDEPT" CHAR(3 OCTETS) , 
		  "PHONENO" CHAR(4 OCTETS) , 
		  "HIREDATE" DATE , 
		  "JOB" CHAR(8 OCTETS) , 
		  "EDLEVEL" SMALLINT NOT NULL , 
		  "SEX" CHAR(1 OCTETS) , 
		  "BIRTHDATE" DATE , 
		  "SALARY" DECIMAL(9,2) , 
		  "BONUS" DECIMAL(9,2) , 
		  "COMM" DECIMAL(9,2) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."EMPLOYEE"

ALTER TABLE "DB2INST1"."EMPLOYEE" 
	ADD CONSTRAINT "PK_EMPLOYEE" PRIMARY KEY
		("EMPNO")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."EMPLOYEE"

CREATE INDEX "DB2INST1"."XEMP2" ON "DB2INST1"."EMPLOYEE" 
		("WORKDEPT" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."EMP_PHOTO"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."EMP_PHOTO"  (
		  "EMPNO" CHAR(6 OCTETS) NOT NULL , 
		  "PHOTO_FORMAT" VARCHAR(10 OCTETS) NOT NULL , 
		  "PICTURE" BLOB(102400) LOGGED NOT COMPACT )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."EMP_PHOTO"

ALTER TABLE "DB2INST1"."EMP_PHOTO" 
	ADD CONSTRAINT "PK_EMP_PHOTO" PRIMARY KEY
		("EMPNO",
		 "PHOTO_FORMAT")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."EMP_RESUME"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."EMP_RESUME"  (
		  "EMPNO" CHAR(6 OCTETS) NOT NULL , 
		  "RESUME_FORMAT" VARCHAR(10 OCTETS) NOT NULL , 
		  "RESUME" CLOB(5120 OCTETS) LOGGED NOT COMPACT )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."EMP_RESUME"

ALTER TABLE "DB2INST1"."EMP_RESUME" 
	ADD CONSTRAINT "PK_EMP_RESUME" PRIMARY KEY
		("EMPNO",
		 "RESUME_FORMAT")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."PROJECT"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."PROJECT"  (
		  "PROJNO" CHAR(6 OCTETS) NOT NULL , 
		  "PROJNAME" VARCHAR(24 OCTETS) NOT NULL WITH DEFAULT '' , 
		  "DEPTNO" CHAR(3 OCTETS) NOT NULL , 
		  "RESPEMP" CHAR(6 OCTETS) NOT NULL , 
		  "PRSTAFF" DECIMAL(5,2) , 
		  "PRSTDATE" DATE , 
		  "PRENDATE" DATE , 
		  "MAJPROJ" CHAR(6 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."PROJECT"

ALTER TABLE "DB2INST1"."PROJECT" 
	ADD CONSTRAINT "PK_PROJECT" PRIMARY KEY
		("PROJNO")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."PROJECT"

CREATE INDEX "DB2INST1"."XPROJ2" ON "DB2INST1"."PROJECT" 
		("RESPEMP" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."PROJACT"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."PROJACT"  (
		  "PROJNO" CHAR(6 OCTETS) NOT NULL , 
		  "ACTNO" SMALLINT NOT NULL , 
		  "ACSTAFF" DECIMAL(5,2) , 
		  "ACSTDATE" DATE NOT NULL , 
		  "ACENDATE" DATE )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."PROJACT"

ALTER TABLE "DB2INST1"."PROJACT" 
	ADD CONSTRAINT "PK_PROJACT" PRIMARY KEY
		("PROJNO",
		 "ACTNO",
		 "ACSTDATE")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."EMPPROJACT"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."EMPPROJACT"  (
		  "EMPNO" CHAR(6 OCTETS) NOT NULL , 
		  "PROJNO" CHAR(6 OCTETS) NOT NULL , 
		  "ACTNO" SMALLINT NOT NULL , 
		  "EMPTIME" DECIMAL(5,2) , 
		  "EMSTDATE" DATE NOT NULL , 
		  "EMENDATE" DATE )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."EMPPROJACT"
-- (added in SAMPLE27; EMSTDATE made NOT NULL)

ALTER TABLE "DB2INST1"."EMPPROJACT"
	ADD CONSTRAINT "PK_EMPPROJACT" PRIMARY KEY
		("EMPNO",
		 "PROJNO",
		 "ACTNO",
		 "EMSTDATE")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."ACT"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."ACT"  (
		  "ACTNO" SMALLINT NOT NULL , 
		  "ACTKWD" CHAR(6 OCTETS) NOT NULL , 
		  "ACTDESC" VARCHAR(20 OCTETS) NOT NULL )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."ACT"

ALTER TABLE "DB2INST1"."ACT" 
	ADD CONSTRAINT "PK_ACT" PRIMARY KEY
		("ACTNO")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."ACT"

CREATE UNIQUE INDEX "DB2INST1"."XACT2" ON "DB2INST1"."ACT" 
		("ACTNO" ASC,
		 "ACTKWD" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."IN_TRAY"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."IN_TRAY"  (
		  "TRAY_ID" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) ,
		  "RECEIVED" TIMESTAMP , 
		  "SOURCE" CHAR(8 OCTETS) , 
		  "SUBJECT" CHAR(64 OCTETS) , 
		  "NOTE_TEXT" VARCHAR(3000 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."IN_TRAY"
-- (added in SAMPLE27; surrogate key)

ALTER TABLE "DB2INST1"."IN_TRAY"
	ADD CONSTRAINT "PK_IN_TRAY" PRIMARY KEY
		("TRAY_ID")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."ORG"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."ORG"  (
		  "DEPTNUMB" SMALLINT NOT NULL , 
		  "DEPTNAME" VARCHAR(14 OCTETS) , 
		  "MANAGER" SMALLINT , 
		  "DIVISION" VARCHAR(10 OCTETS) , 
		  "LOCATION" VARCHAR(13 OCTETS) )
		 IN "USERSPACE1"
		 ORGANIZE BY ROW;


-- DDL Statements for Primary Key on Table "DB2INST1"."ORG"
-- (added in SAMPLE27)

ALTER TABLE "DB2INST1"."ORG"
	ADD CONSTRAINT "PK_ORG" PRIMARY KEY
		("DEPTNUMB")
	ENFORCED;





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."STAFF"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."STAFF"  (
		  "ID" SMALLINT NOT NULL , 
		  "NAME" VARCHAR(9 OCTETS) , 
		  "DEPT" SMALLINT , 
		  "JOB" CHAR(5 OCTETS) , 
		  "YEARS" SMALLINT , 
		  "SALARY" DECIMAL(9,2) , 
		  "COMM" DECIMAL(9,2) )
		 IN "USERSPACE1"
		 ORGANIZE BY ROW;


-- DDL Statements for Primary Key on Table "DB2INST1"."STAFF"
-- (added in SAMPLE27)

ALTER TABLE "DB2INST1"."STAFF"
	ADD CONSTRAINT "PK_STAFF" PRIMARY KEY
		("ID")
	ENFORCED;





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."SALES"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."SALES"  (
		  "SALES_ID" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) ,
		  "SALES_DATE" DATE , 
		  "SALES_PERSON" VARCHAR(15 OCTETS) , 
		  "REGION" VARCHAR(15 OCTETS) , 
		  "SALES" INTEGER )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."SALES"
-- (added in SAMPLE27; surrogate key)

ALTER TABLE "DB2INST1"."SALES"
	ADD CONSTRAINT "PK_SALES" PRIMARY KEY
		("SALES_ID")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."STAFFG"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."STAFFG"  (
		  "ID" SMALLINT NOT NULL , 
		  "NAME" VARGRAPHIC(9 CODEUNITS16) , 
		  "DEPT" SMALLINT , 
		  "JOB" GRAPHIC(5 CODEUNITS16) , 
		  "YEARS" SMALLINT , 
		  "SALARY" DECIMAL(9,0) , 
		  "COMM" DECIMAL(9,0) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."STAFFG"
-- (added in SAMPLE27)

ALTER TABLE "DB2INST1"."STAFFG"
	ADD CONSTRAINT "PK_STAFFG" PRIMARY KEY
		("ID")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."ADEFUSR"
------------------------------------------------

CREATE SUMMARY TABLE ADEFUSR AS (SELECT workdept, count(*) AS no_of_employees FROM employee GROUP BY workdept) DATA INITIALLY DEFERRED REFRESH IMMEDIATE ENABLE QUERY OPTIMIZATION MAINTAINED BY SYSTEM IN "USERSPACE1" 		ORGANIZE BY ROW;


ALTER TABLE "DB2INST1"."ADEFUSR" DEACTIVATE ROW ACCESS CONTROL;





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."EMPMDC"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."EMPMDC"  (
		  "EMPNO" INTEGER NOT NULL , 
		  "DEPT" INTEGER , 
		  "DIV" INTEGER )   
		 IN "IBMDB2SAMPLEREL"  
		 ORGANIZE BY ROW USING ( 
		  ( "DEPT" ) , 
		  ( "DIV" ) ) 
		 ;

-- DDL Statements for Primary Key on Table "DB2INST1"."EMPMDC"
-- (added in SAMPLE27; EMPNO made NOT NULL)

ALTER TABLE "DB2INST1"."EMPMDC"
	ADD CONSTRAINT "PK_EMPMDC" PRIMARY KEY
		("EMPNO")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."PRODUCT"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."PRODUCT"  (
		  "PID" VARCHAR(10 OCTETS) NOT NULL , 
		  "NAME" VARCHAR(128 OCTETS) , 
		  "PRICE" DECIMAL(30,2) , 
		  "PROMOPRICE" DECIMAL(30,2) , 
		  "PROMOSTART" DATE , 
		  "PROMOEND" DATE , 
		  "DESCRIPTION" XML )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."PRODUCT"

ALTER TABLE "DB2INST1"."PRODUCT" 
	ADD CONSTRAINT "PK_PRODUCT" PRIMARY KEY
		("PID")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."PRODUCT"

CREATE INDEX "DB2INST1"."PROD_NAME_XMLIDX" ON "DB2INST1"."PRODUCT" 
		("DESCRIPTION" ASC)
		GENERATE KEY USING XMLPATTERN '/product/description/name'
		  AS SQL VARCHAR  ( 128 OCTETS ) IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."PRODUCT"

CREATE INDEX "DB2INST1"."PROD_DETAIL_XMLIDX" ON "DB2INST1"."PRODUCT" 
		("DESCRIPTION" ASC)
		GENERATE KEY USING XMLPATTERN '/product/description/detail'
		  AS SQL VARCHAR  HASHED IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."INVENTORY"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."INVENTORY"  (
		  "PID" VARCHAR(10 OCTETS) NOT NULL , 
		  "QUANTITY" INTEGER , 
		  "LOCATION" VARCHAR(128 OCTETS) )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."INVENTORY"

ALTER TABLE "DB2INST1"."INVENTORY" 
	ADD CONSTRAINT "PK_INVENTORY" PRIMARY KEY
		("PID")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."CUSTOMER"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."CUSTOMER"  (
		  "CID" BIGINT NOT NULL , 
		  "INFO" XML , 
		  "HISTORY" XML )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."CUSTOMER"

ALTER TABLE "DB2INST1"."CUSTOMER" 
	ADD CONSTRAINT "PK_CUSTOMER" PRIMARY KEY
		("CID")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."CUSTOMER"

CREATE UNIQUE INDEX "DB2INST1"."CUST_CID_XMLIDX" ON "DB2INST1"."CUSTOMER" 
		("INFO" ASC)
		GENERATE KEY USING XMLPATTERN '/customerinfo/@Cid'
		  AS SQL DOUBLE   IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."CUSTOMER"

CREATE INDEX "DB2INST1"."CUST_NAME_XMLIDX" ON "DB2INST1"."CUSTOMER" 
		("INFO" ASC)
		GENERATE KEY USING XMLPATTERN '/customerinfo/name'
		  AS SQL VARCHAR  ( 50 OCTETS ) IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."CUSTOMER"

CREATE INDEX "DB2INST1"."CUST_PHONES_XMLIDX" ON "DB2INST1"."CUSTOMER" 
		("INFO" ASC)
		GENERATE KEY USING XMLPATTERN '/customerinfo/phone'
		  AS SQL VARCHAR  ( 25 OCTETS ) IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."CUSTOMER"

CREATE INDEX "DB2INST1"."CUST_PHONET_XMLIDX" ON "DB2INST1"."CUSTOMER" 
		("INFO" ASC)
		GENERATE KEY USING XMLPATTERN '/customerinfo/phone/@type'
		  AS SQL VARCHAR  ( 25 OCTETS ) IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."PURCHASEORDER"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."PURCHASEORDER"  (
		  "POID" BIGINT NOT NULL , 
		  "STATUS" VARCHAR(10 OCTETS) NOT NULL WITH DEFAULT 'Unshipped' , 
		  "CUSTID" BIGINT , 
		  "ORDERDATE" DATE , 
		  "PORDER" XML , 
		  "COMMENTS" VARCHAR(1000 OCTETS) )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."PURCHASEORDER"

ALTER TABLE "DB2INST1"."PURCHASEORDER" 
	ADD CONSTRAINT "PK_PURCHASEORDER" PRIMARY KEY
		("POID")
	ENFORCED;



-- DDL Statements for Indexes on Table "DB2INST1"."PURCHASEORDER"

CREATE INDEX "DB2INST1"."PO_PRODS_XMLIDX" ON "DB2INST1"."PURCHASEORDER" 
		("PORDER" ASC)
		GENERATE KEY USING XMLPATTERN '/PurchaseOrder/itemlist/item/product/@pid'
		  AS SQL DOUBLE   IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."PURCHASEORDER"

CREATE INDEX "DB2INST1"."PO_CID_XMLIDX" ON "DB2INST1"."PURCHASEORDER" 
		("PORDER" ASC)
		GENERATE KEY USING XMLPATTERN '/PurchaseOrder/@Cid'
		  AS SQL DOUBLE   IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DB2INST1"."PURCHASEORDER"

CREATE INDEX "DB2INST1"."PO_ZIP_XMLIDX" ON "DB2INST1"."PURCHASEORDER" 
		("PORDER" ASC)
		GENERATE KEY USING XMLPATTERN '/PurchaseOrder/customerAdr/addr/pcode-zip'
		  AS SQL VARCHAR  ( 16 OCTETS ) IGNORE INVALID VALUES 
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;
------------------------------------------------
-- DDL Statements for Table "DB2INST1"."CATALOG"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."CATALOG"  (
		  "NAME" VARCHAR(128 OCTETS) NOT NULL , 
		  "CATLOG" XML )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."CATALOG"

ALTER TABLE "DB2INST1"."CATALOG" 
	ADD CONSTRAINT "PK_CATALOG" PRIMARY KEY
		("NAME")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."SUPPLIERS"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."SUPPLIERS"  (
		  "SID" VARCHAR(10 OCTETS) NOT NULL , 
		  "ADDR" XML )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."SUPPLIERS"

ALTER TABLE "DB2INST1"."SUPPLIERS" 
	ADD CONSTRAINT "PK_SUPPLIERS" PRIMARY KEY
		("SID")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."PRODUCTSUPPLIER"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."PRODUCTSUPPLIER"  (
		  "PID" VARCHAR(10 OCTETS) NOT NULL , 
		  "SID" VARCHAR(10 OCTETS) NOT NULL )   
		 IN "IBMDB2SAMPLEXML"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DB2INST1"."PRODUCTSUPPLIER"

ALTER TABLE "DB2INST1"."PRODUCTSUPPLIER" 
	ADD CONSTRAINT "PK_PRODUCTSUPPLIER" PRIMARY KEY
		("PID",
		 "SID")
	ENFORCED;


------------------------------------------------
-- DDL Statements for Table "DB2INST1"."PATIENTS"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."PATIENTS"  (
		  "PATIENT_ID" INTEGER NOT NULL ,
		  "NAME" VARCHAR(30 OCTETS) , 
		  "AGE" INTEGER , 
		  "GENDER" VARCHAR(6 OCTETS) , 
		  "CHOLESTEROL_LEVEL" INTEGER , 
		  "BLOOD_PRESSURE" INTEGER , 
		  "SMOKING_STATUS" VARCHAR(10 OCTETS) , 
		  "EMBEDDING" VECTOR(768,FLOAT32) )
		 IN "IBMDB2SAMPLEVECTOR"
		 ORGANIZE BY ROW;


-- DDL Statements for Primary Key on Table "DB2INST1"."PATIENTS"
-- (added in SAMPLE27; PATIENT_ID was nullable and is now NOT NULL)

ALTER TABLE "DB2INST1"."PATIENTS"
	ADD CONSTRAINT "PK_PATIENTS" PRIMARY KEY
		("PATIENT_ID")
	ENFORCED;





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."MLBLOGS_QUESTIONS"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."MLBLOGS_QUESTIONS"  (
		  "QUESTION_ID" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) ,
		  "QUESTION" VARCHAR(1024 OCTETS) , 
		  "EMBEDDING" VECTOR(1024,FLOAT32) )   
		 IN "IBMDB2SAMPLEVECTOR"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."MLBLOGS_QUESTIONS"
-- (added in SAMPLE27; surrogate key)

ALTER TABLE "DB2INST1"."MLBLOGS_QUESTIONS"
	ADD CONSTRAINT "PK_MLBLOGS_QUESTIONS" PRIMARY KEY
		("QUESTION_ID")
	ENFORCED;
 





------------------------------------------------
-- DDL Statements for Table "DB2INST1"."MLBLOGS_ANSWERS"
------------------------------------------------
 

CREATE TABLE "DB2INST1"."MLBLOGS_ANSWERS"  (
		  "ANSWER_ID" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) ,
		  "ANSWER" VARCHAR(1024 OCTETS) , 
		  "EMBEDDING" VECTOR(1024,FLOAT32) )   
		 IN "IBMDB2SAMPLEVECTOR"  
		 ORGANIZE BY ROW;

-- DDL Statements for Primary Key on Table "DB2INST1"."MLBLOGS_ANSWERS"
-- (added in SAMPLE27; surrogate key)

ALTER TABLE "DB2INST1"."MLBLOGS_ANSWERS"
	ADD CONSTRAINT "PK_MLBLOGS_ANSWERS" PRIMARY KEY
		("ANSWER_ID")
	ENFORCED;
 





-- DDL Statements for Foreign Keys on Table "DB2INST1"."DEPARTMENT"

ALTER TABLE "DB2INST1"."DEPARTMENT" 
	ADD CONSTRAINT "RDE" FOREIGN KEY
		("MGRNO")
	REFERENCES "DB2INST1"."EMPLOYEE"
		("EMPNO")
	ON DELETE SET NULL
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DB2INST1"."DEPARTMENT" 
	ADD CONSTRAINT "ROD" FOREIGN KEY
		("ADMRDEPT")
	REFERENCES "DB2INST1"."DEPARTMENT"
		("DEPTNO")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."EMPLOYEE"

ALTER TABLE "DB2INST1"."EMPLOYEE" 
	ADD CONSTRAINT "RED" FOREIGN KEY
		("WORKDEPT")
	REFERENCES "DB2INST1"."DEPARTMENT"
		("DEPTNO")
	ON DELETE SET NULL
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Check Constraints on Table "DB2INST1"."EMPLOYEE"

ALTER TABLE "DB2INST1"."EMPLOYEE" 
	ADD CONSTRAINT "NUMBER" CHECK 
		(PHONENO >= '0000' AND PHONENO <= '9999')
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."EMP_PHOTO"

ALTER TABLE "DB2INST1"."EMP_PHOTO" 
	ADD CONSTRAINT "FK_EMP_PHOTO" FOREIGN KEY
		("EMPNO")
	REFERENCES "DB2INST1"."EMPLOYEE"
		("EMPNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."EMP_RESUME"

ALTER TABLE "DB2INST1"."EMP_RESUME" 
	ADD CONSTRAINT "FK_EMP_RESUME" FOREIGN KEY
		("EMPNO")
	REFERENCES "DB2INST1"."EMPLOYEE"
		("EMPNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."PROJECT"

ALTER TABLE "DB2INST1"."PROJECT" 
	ADD CONSTRAINT "FK_PROJECT_1" FOREIGN KEY
		("DEPTNO")
	REFERENCES "DB2INST1"."DEPARTMENT"
		("DEPTNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DB2INST1"."PROJECT" 
	ADD CONSTRAINT "FK_PROJECT_2" FOREIGN KEY
		("RESPEMP")
	REFERENCES "DB2INST1"."EMPLOYEE"
		("EMPNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DB2INST1"."PROJECT" 
	ADD CONSTRAINT "RPP" FOREIGN KEY
		("MAJPROJ")
	REFERENCES "DB2INST1"."PROJECT"
		("PROJNO")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."PROJACT"

ALTER TABLE "DB2INST1"."PROJACT" 
	ADD CONSTRAINT "RPAP" FOREIGN KEY
		("PROJNO")
	REFERENCES "DB2INST1"."PROJECT"
		("PROJNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."EMPPROJACT"

ALTER TABLE "DB2INST1"."EMPPROJACT" 
	ADD CONSTRAINT "REPAPA" FOREIGN KEY
		("PROJNO",
		 "ACTNO",
		 "EMSTDATE")
	REFERENCES "DB2INST1"."PROJACT"
		("PROJNO",
		 "ACTNO",
		 "ACSTDATE")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- The original script declared "RPAA" as ACT(ACTNO) -> ACT(ACTNO), a self-reference
-- that enforces nothing. The intended relationship is PROJACT -> ACT.

ALTER TABLE "DB2INST1"."PROJACT"
	ADD CONSTRAINT "RPAA" FOREIGN KEY
		("ACTNO")
	REFERENCES "DB2INST1"."ACT"
		("ACTNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DB2INST1"."EMPPROJACT"
	ADD CONSTRAINT "FK_EMPPROJACT_EMP" FOREIGN KEY
		("EMPNO")
	REFERENCES "DB2INST1"."EMPLOYEE"
		("EMPNO")
	ON DELETE RESTRICT
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."INVENTORY"

ALTER TABLE "DB2INST1"."INVENTORY"
	ADD CONSTRAINT "FK_INVENTORY_PROD" FOREIGN KEY
		("PID")
	REFERENCES "DB2INST1"."PRODUCT"
		("PID")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DB2INST1"."PRODUCTSUPPLIER"

ALTER TABLE "DB2INST1"."PRODUCTSUPPLIER"
	ADD CONSTRAINT "FK_PRODSUPP_PROD" FOREIGN KEY
		("PID")
	REFERENCES "DB2INST1"."PRODUCT"
		("PID")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DB2INST1"."PRODUCTSUPPLIER"
	ADD CONSTRAINT "FK_PRODSUPP_SUPP" FOREIGN KEY
		("SID")
	REFERENCES "DB2INST1"."SUPPLIERS"
		("SID")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- Date-range check constraints are added by data_fixes.sql, after the data has been repaired.

-- DDL Statements for Indexes supporting Foreign Keys

CREATE INDEX "DB2INST1"."XPROJACT2" ON "DB2INST1"."PROJACT" ("ACTNO" ASC);

CREATE INDEX "DB2INST1"."XEMPPROJACT2" ON "DB2INST1"."EMPPROJACT"
		("PROJNO" ASC, "ACTNO" ASC, "EMSTDATE" ASC);

CREATE INDEX "DB2INST1"."XPRODSUPP2" ON "DB2INST1"."PRODUCTSUPPLIER" ("SID" ASC);

CREATE INDEX "DB2INST1"."XPO2" ON "DB2INST1"."PURCHASEORDER" ("CUSTID" ASC);

-- DDL Statements for Foreign Keys on Table "DB2INST1"."PURCHASEORDER"

ALTER TABLE "DB2INST1"."PURCHASEORDER" 
	ADD CONSTRAINT "FK_PO_CUST" FOREIGN KEY
		("CUSTID")
	REFERENCES "DB2INST1"."CUSTOMER"
		("CID")
	ON DELETE CASCADE
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;






---------------------------------
-- DDL Statements for User Defined Functions
---------------------------------



CREATE OR REPLACE FUNCTION resign_employee (number CHAR(6))
  RETURNS TABLE (empno  CHAR(6),
                 salary DOUBLE,
                 dept   CHAR(3))
  MODIFIES SQL DATA
  LANGUAGE SQL
  BEGIN ATOMIC
-- -------------------------------------------------------------------------------------
-- Routine type:  SQL table function
-- Routine name:  resign_employee
--
-- Purpose:  This procedure takes in an employee number, then removes that
--           employee from the EMPLOYEE table.
--           A useful extension to this function would be to archive the
--           original record into an archive table.
--
-- --------------------------------------------------------------------------------------
    DECLARE l_salary DOUBLE;--
    DECLARE l_dept CHAR(3);--

    SET (l_salary, l_dept) = (SELECT salary, workdept
                               FROM OLD TABLE (DELETE FROM employee
                                                WHERE employee.empno = number));--

    RETURN VALUES (number,l_salary, l_dept);--
  END
;


-- DDL Statements for Aliases

CREATE ALIAS "DB2INST1"."DEPT" FOR TABLE "DB2INST1"."DEPARTMENT";

CREATE ALIAS "DB2INST1"."EMP" FOR TABLE "DB2INST1"."EMPLOYEE";

CREATE ALIAS "DB2INST1"."EMPACT" FOR TABLE "DB2INST1"."EMPPROJACT";

CREATE ALIAS "DB2INST1"."EMP_ACT" FOR TABLE "DB2INST1"."EMPPROJACT";

CREATE ALIAS "DB2INST1"."PROJ" FOR TABLE "DB2INST1"."PROJECT";


----------------------------

-- DDL Statements for Views

----------------------------
CREATE VIEW VDEPT      AS SELECT ALL DEPTNO,   DEPTNAME,   MGRNO,   ADMRDEPT
  FROM DEPT;

CREATE VIEW VHDEPT    AS SELECT ALL DEPTNO ,   DEPTNAME,   MGRNO ,   ADMRDEPT,
  LOCATION   FROM DEPT;

CREATE VIEW VEMP    AS SELECT ALL EMPNO ,   FIRSTNME,   MIDINIT ,   LASTNAME,
  WORKDEPT   FROM EMP;

CREATE VIEW VPROJ    AS SELECT ALL PROJNO, PROJNAME, DEPTNO, RESPEMP, PRSTAFF,
PRSTDATE, PRENDATE, MAJPROJ FROM PROJ;

CREATE VIEW VACT AS SELECT ALL ACTNO ,   ACTKWD ,   ACTDESC FROM ACT;

CREATE VIEW VPROJACT    AS SELECT ALL PROJNO,ACTNO, ACSTAFF, ACSTDATE, ACENDATE
FROM PROJACT;

CREATE VIEW VEMPPROJACT AS SELECT ALL EMPNO, PROJNO, ACTNO, EMPTIME, EMSTDATE,
EMENDATE FROM EMPPROJACT;

CREATE VIEW VDEPMG1 (DEPTNO, DEPTNAME, MGRNO, FIRSTNME, MIDINIT,   LASTNAME,
ADMRDEPT) AS SELECT ALL DEPTNO, DEPTNAME, EMPNO, FIRSTNME, MIDINIT,   LASTNAME,
ADMRDEPT FROM DEPT LEFT OUTER  JOIN EMP ON MGRNO = EMPNO;

CREATE VIEW VEMPDPT1 (DEPTNO, DEPTNAME, EMPNO, FRSTINIT, MIDINIT,   LASTNAME,
WORKDEPT) AS SELECT ALL DEPTNO, DEPTNAME, EMPNO, SUBSTR(FIRSTNME, 1, 1),
MIDINIT,   LASTNAME, WORKDEPT FROM DEPT  RIGHT OUTER JOIN EMP ON WORKDEPT
= DEPTNO;

CREATE VIEW VASTRDE1   (DEPT1NO,DEPT1NAM,EMP1NO,EMP1FN,EMP1MI,EMP1LN,TYPE2,
  DEPT2NO,DEPT2NAM,EMP2NO,EMP2FN,EMP2MI,EMP2LN) AS SELECT ALL   D1.DEPTNO,D1.DEPTNAME,D1.MGRNO,D1.FIRSTNME,D1.MIDINIT,
  D1.LASTNAME, '1',   D2.DEPTNO,D2.DEPTNAME,D2.MGRNO,D2.FIRSTNME,D2.MIDINIT,
  D2.LASTNAME FROM VDEPMG1 D1, VDEPMG1 D2 WHERE D1.DEPTNO = D2.ADMRDEPT;

CREATE VIEW VASTRDE2   (DEPT1NO,DEPT1NAM,EMP1NO,EMP1FN,EMP1MI,EMP1LN,TYPE2,
  DEPT2NO,DEPT2NAM,EMP2NO,EMP2FN,EMP2MI,EMP2LN) AS SELECT ALL   D1.DEPTNO,D1.DEPTNAME,D1.MGRNO,D1.FIRSTNME,D1.MIDINIT,
  D1.LASTNAME,'2',   D1.DEPTNO,D1.DEPTNAME,E2.EMPNO,E2.FIRSTNME,E2.MIDINIT,
  E2.LASTNAME FROM VDEPMG1 D1, EMP E2 WHERE D1.DEPTNO = E2.WORKDEPT;

CREATE VIEW VPROJRE1   (PROJNO,PROJNAME,PROJDEP,RESPEMP,FIRSTNME,MIDINIT,
  LASTNAME,MAJPROJ) AS SELECT ALL   PROJNO,PROJNAME,DEPTNO,EMPNO,FIRSTNME,MIDINIT,
  LASTNAME,MAJPROJ FROM PROJ, EMP WHERE RESPEMP = EMPNO;

CREATE VIEW VPSTRDE1   (PROJ1NO,PROJ1NAME,RESP1NO,RESP1FN,RESP1MI,RESP1LN,
  PROJ2NO,PROJ2NAME,RESP2NO,RESP2FN,RESP2MI,RESP2LN) AS SELECT ALL   P1.PROJNO,P1.PROJNAME,P1.RESPEMP,P1.FIRSTNME,P1.MIDINIT,
  P1.LASTNAME,   P2.PROJNO,P2.PROJNAME,P2.RESPEMP,P2.FIRSTNME,P2.MIDINIT,
  P2.LASTNAME FROM VPROJRE1 P1,   VPROJRE1 P2 WHERE P1.PROJNO = P2.MAJPROJ;

CREATE VIEW VPSTRDE2   (PROJ1NO,PROJ1NAME,RESP1NO,RESP1FN,RESP1MI,RESP1LN,
  PROJ2NO,PROJ2NAME,RESP2NO,RESP2FN,RESP2MI,RESP2LN) AS SELECT ALL   P1.PROJNO,P1.PROJNAME,P1.RESPEMP,P1.FIRSTNME,P1.MIDINIT,
  P1.LASTNAME,   P1.PROJNO,P1.PROJNAME,P1.RESPEMP,P1.FIRSTNME,P1.MIDINIT,
  P1.LASTNAME FROM VPROJRE1 P1 WHERE NOT EXISTS (SELECT * FROM VPROJRE1
P2 WHERE P1.PROJNO = P2.MAJPROJ);

CREATE VIEW VFORPLA   (PROJNO,PROJNAME,RESPEMP,PROJDEP,FRSTINIT,MIDINIT,LASTNAME)
AS SELECT ALL F1.PROJNO,PROJNAME,RESPEMP,PROJDEP, SUBSTR(FIRSTNME, 1, 1),
  MIDINIT, LASTNAME FROM VPROJRE1 F1 LEFT OUTER JOIN EMPPROJACT F2 ON F1.PROJNO
= F2.PROJNO;

CREATE VIEW VSTAFAC1(PROJNO, ACTNO, ACTDESC, EMPNO, FIRSTNME, MIDINIT, 
    LASTNAME, EMPTIME,STDATE,ENDATE, TYPE) AS SELECT ALL PA.PROJNO, PA.ACTNO,
AC.ACTDESC,' ', ' ', ' ', ' ',   PA.ACSTAFF, PA.ACSTDATE,   PA.ACENDATE,'1'
FROM PROJACT PA, ACT AC  WHERE PA.ACTNO = AC.ACTNO;

CREATE VIEW VSTAFAC2 (PROJNO, ACTNO, ACTDESC, EMPNO, FIRSTNME, MIDINIT,
LASTNAME, EMPTIME,STDATE, ENDATE, TYPE) AS SELECT ALL EP.PROJNO, EP.ACTNO,
AC.ACTDESC, EP.EMPNO,EM.FIRSTNME, EM.MIDINIT, EM.LASTNAME, EP.EMPTIME,
EP.EMSTDATE,   EP.EMENDATE,'2' FROM EMPPROJACT EP, ACT AC, EMP EM WHERE
EP.ACTNO = AC.ACTNO AND EP.EMPNO = EM.EMPNO;

CREATE VIEW VPHONE   (LASTNAME,   FIRSTNAME,   MIDDLEINITIAL,   PHONENUMBER,
  EMPLOYEENUMBER,   DEPTNUMBER,   DEPTNAME) AS SELECT ALL LASTNAME,   FIRSTNME,
  MIDINIT ,   VALUE(PHONENO,' '),   EMPNO,   DEPTNO,   DEPTNAME FROM EMP,
DEPT WHERE WORKDEPT = DEPTNO;

CREATE VIEW VEMPLP   (EMPLOYEENUMBER,   PHONENUMBER) AS SELECT ALL EMPNO
,   PHONENO FROM EMP;




---------------------------------
-- DDL Statements for Stored Procedures
---------------------------------



CREATE PROCEDURE bonus_increase                            (IN p_bonusFactor
DECIMAL (3,2),                              IN p_bonusMaxSumForDept DECIMAL
(9,2),                              OUT p_deptsWithoutNewBonuses VARCHAR(255),
                             OUT p_countDeptsViewed INTEGER,          
                   OUT p_countDeptsBonusChanged INTEGER,              
               OUT p_errorMsg VARCHAR(255)) SPECIFIC BONUS_INCREASE
LANGUAGE SQL
DYNAMIC RESULT SETS 1

BEGIN
-- -------------------------------------------------------------------------------------
-- Routine type:  SQL stored procedure
-- Routine name:  bonus_increase
--
-- Purpose:  This procedure takes in a multiplier value that is used to update
--           employee bonus values.  The employee bonus updates are done department
--           by department.  Updated employee bonus values are only committed if the
--           sum of the bonuses for a department does not exceed the threshold amount
--           specified by another input parameter.  A result is returned listing, by
--           department, employee numbers and currently set bonus values.
--
-- Features shown:
--           - IN and OUT parameters
--           - Variable declaration and setting
--           - Condition handler declaration and use
--           - Use of CURSOR WITH HOLD
--           - Use of SAVEPOINT and ROLLBACK to SAVEPOINT
--           - Returning of a result set to the caller
--           - Use of a WHILE loop control-statement
--           - Use of IF/ELSE statement
--           - Use of labels and GOTO statement
--           - Use of RETURN statement
--
-- Parameters:
-- IN  p_bonusFactor:      Constant multiple by which employee bonuses are updated
-- IN  p_bonusMaxSumForDept:    Maximum amount for departmental bonuses without review
-- OUT p_deptsWithoutNewBonuses:  Comma delimited list of departments that require
--                                   a manual setting and review of bonus amounts
-- OUT p_countDeptsViewed:     Number of departments processed
-- OUT p_countDeptsBonusChanged:  Number of departments for which bonuses were set
-- OUT p_errorMsg:       Error message string
-- --------------------------------------------------------------------------------------
    DECLARE v_dept, v_actdept CHAR(3);--
    DECLARE v_bonus, v_deptbonus, v_newbonus DECIMAL(9,2);--
    DECLARE v_empno CHAR(6);--
    DECLARE v_atend SMALLINT DEFAULT 0;--
    DECLARE SQLSTATE CHAR(5) DEFAULT '00000';--

    -- Cursor that lists employee numbers and bonuses ordered by department
    -- This cursor is declared as WITH HOLD so that on rollbacks it remains
    -- open.  It is declared as FOR UPDATE OF bonus, so that the employee
    -- bonus column field can be updated as the cursor iterates through the rows.

    DECLARE cSales CURSOR WITH HOLD FOR
          SELECT workdept, bonus, empno FROM employee ORDER BY workdept
      FOR UPDATE OF bonus;--

    -- This cursor, declared with WITH RETURN TO CALLER, is used to return
    -- a result set to the caller when this procedure returns.  The result
    -- set contains a list of the employees and their bonus values ordered
    -- by the department numbers.

    DECLARE cEmpBonuses CURSOR WITH RETURN TO CALLER FOR
          SELECT workdept, empno, bonus FROM employee ORDER BY workdept;--

    -- This continue handler is used to catch the NOT FOUND error
    -- associated with the end of the iteration over the cursor cSales.
    -- It is used to set v_atend which flags the end of the WHILE loop.

     DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_atend=1;--

    -- This continue handler is used to catch any numeric overflows

    DECLARE EXIT HANDLER FOR SQLSTATE '22003'
    BEGIN
      SET p_errorMsg = 'SQLSTATE 22003 - Numeric overflow occurred setting bonus';--
    END;--

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      SET p_errorMsg = 'Unexpected SQL error, SQLSTATE ' || COALESCE(SQLSTATE, '?');--
      SET v_atend = 1;--
    END;--

    -- Initialize local variables

    SET p_errorMsg = '';--
    SET p_deptsWithoutNewBonuses = '';--
    SET p_countDeptsViewed = 0;--
    SET p_countDeptsBonusChanged = 0;--

    -- Check input parameter is valid

    IF (p_bonusFactor < 1 OR p_bonusFactor > 2) THEN
      SET p_errorMsg = 'E01 Checking parameter p_bonusFactor, validation';--
      GOTO error_found;--
    END IF;--

    OPEN cSales;--

    FETCH cSales INTO v_dept, v_bonus, v_empno;--

    nextdept:
        IF v_atend = 0 THEN

            -- This savepoint is used to rollback the bonuses assigned to employees if
            -- the sum of bonuses for a department exceeds a threshold amount

            SAVEPOINT svpt_bonus ON ROLLBACK RETAIN CURSORS;--

            SET v_actdept = v_dept;--
            SET v_deptbonus = 0;--

            WHILE ( v_actdept = v_dept ) AND ( v_atend = 0 ) DO
                    SET v_newbonus = v_bonus * p_bonusFactor;--
                    UPDATE employee SET bonus = v_newbonus WHERE empno = v_empno;--
                    SET v_deptbonus = v_deptbonus + v_newbonus;--
                    FETCH cSales INTO v_dept, v_bonus, v_empno;--
            END WHILE;--

            SET p_countDeptsViewed = p_countDeptsViewed + 1;--

            IF v_deptbonus <= p_bonusMaxSumForDept THEN
                SET p_countDeptsBonusChanged = p_countDeptsBonusChanged + 1;--
                COMMIT;--
            ELSE
                     ROLLBACK TO SAVEPOINT svpt_bonus;--
                     RELEASE SAVEPOINT svpt_bonus;--
                     SET p_deptsWithoutNewBonuses =
                                     (CASE WHEN p_deptsWithoutNewBonuses = ''
                                           THEN v_actdept
                                      ELSE
                                           p_deptsWithoutNewBonuses || ', ' || v_actdept
                                      END);--
            END IF;--
            GOTO nextdept;--
        END IF;--

    OPEN cEmpBonuses;--

    RETURN 0;--

error_found:
    SET p_errorMsg = p_errorMsg || ' failed.';--
    RETURN -1;--

END;

-------------------------------
-- DDL Statements for Triggers
-------------------------------


CREATE TRIGGER do_not_del_sales NO CASCADE BEFORE DELETE ON staff REFERENCING
OLD AS oldstaff FOR EACH ROW MODE DB2SQL WHEN(oldstaff.job = 'Sales') BEGIN
ATOMIC SIGNAL SQLSTATE '75000' ('Sales staff cannot be deleted... see the DO_NOT_DEL_SALES trigger.');--
END;


CREATE TRIGGER min_salary NO CASCADE BEFORE INSERT ON staff REFERENCING
NEW AS newstaff FOR EACH ROW MODE DB2SQL BEGIN ATOMIC SET newstaff.salary
= CASE WHEN newstaff.job = 'Mgr' AND newstaff.salary < 17000.00 THEN 17000.00
WHEN newstaff.job = 'Sales' AND newstaff.salary < 14000.00 THEN 14000.00
WHEN newstaff.job = 'Clerk' AND newstaff.salary < 10000.00 THEN 10000.00
ELSE newstaff.salary END; END;


-- ADEFUSR was created DATA INITIALLY DEFERRED; populate it once data is loaded.
REFRESH TABLE "DB2INST1"."ADEFUSR";

COMMIT WORK;

CONNECT RESET;

TERMINATE;

