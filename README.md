# SAMPLE27

SAMPLE27 is the Db2 `SAMPLE` database, rebuilt from files, repaired where it was broken, and checked by an automated build.
It keeps the 25 tables, their names, the XML, MDC, MQT and VECTOR features, and the old data (hire dates from 1977, sales from 1996, mail from 1988).
It changes only what could not be true or could not be rebuilt.

- Target: IBM Db2 12.1 LUW, tested on **12.1.5.0**.
- One script drops and recreates the database from the files and asserts the result.
- It does not need the original `SAMPLE`. The original data is created by Db2 itself during the build (`db2sampl`, in a temporary database that is dropped again). This repository contains no data of the original `SAMPLE`. If you have `SAMPLE`, it is never touched: SAMPLE27 is a separate database.

**Contents**

1. [Download the schema](#download-the-schema)
2. [Prerequisites](#prerequisites)
3. [Install](#install)
4. [Testing steps, with examples](#testing-steps-with-examples)
5. [Compatibility with the Db2 sample programs](#compatibility-with-the-db2-sample-programs)
6. [What was wrong with SAMPLE, and what SAMPLE27 changes](#what-was-wrong-with-sample-and-what-sample27-changes)
7. [Synthetic rows](#synthetic-rows)
8. [Repository layout](#repository-layout)
9. [Licence and attribution](#licence-and-attribution)

---

## Download the schema

| File | What it is |
|---|---|
| [`ddl/sample27.ddl`](ddl/sample27.ddl) | The complete SAMPLE27 schema: tablespaces, schema, 25 tables and the summary table, keys, indexes, 5 aliases, 19 views, 2 routines, 2 triggers, 1 sequence. Runs with 0 errors on an empty Db2 12.1.5 database. |

Single file: on the GitHub page of `ddl/sample27.ddl` use **Raw** or **Download raw file**. Whole repository: **Code → Download ZIP**.

To create only the schema, without data, as the instance owner:

```bash
db2 "CREATE DATABASE SAMPLE27 USING CODESET UTF-8 TERRITORY US PAGESIZE 8192"
db2 -tvf ddl/sample27.ddl          # the script connects to SAMPLE27 itself
```

The page size must be 8192: the three tablespaces at the top of the script are 8 KB.
With the default 4 KB page size, Db2 rejects them with `SQL1582N`.

---

## Prerequisites

| Needed | Details |
|---|---|
| Db2 12.1.5 LUW | Tested on 12.1.5.0 only. Vectors and `CREATE EXTERNAL MODEL` are 12.1.x features, so earlier releases will not load the `VECTOR` tables. How Db2 was installed does not matter: directly into the system or in a container, the build only needs the `db2` command |
| A user who can create databases | The instance owner (`db2inst1` on Linux) is the simplest |
| Linux: bash | The build script is bash. Run it as the instance owner, with the instance profile loaded (`. ~/sqllib/db2profile`) |
| Windows: a Db2 command window | There is no Windows build script. Run the SQL files by hand, in the order given under [Install on Windows](#install-on-windows) |
| Page size | The build creates the database with `PAGESIZE 8192`. If you use your own database, it must have an 8 KB page size |
| Time and space | A full build took about 2.5 minutes with x86-64 Db2 under emulation on an Apple-silicon Mac. The temporary `S27SRC` database needs about 300 MB of disk while it exists (3 MB of exported files) |
| Optional: `gcc` and the Db2 sample sources | Only for the sample-program checks below. They are in `samples` of the Db2 install |

**Existing `SAMPLE`.** Having `SAMPLE` on the instance or not makes no difference. The build needs no `SAMPLE`: it takes the original data from a temporary database made by `db2sampl`. It creates, drops and recreates only `SAMPLE27`, and never touches `SAMPLE`.

**What was and was not tested.** The build was run, with every assertion passing, on Db2 12.1.5.0 for Linux x86-64: in a container on an Apple-silicon Mac (emulated), and in a Db2 container under Podman on a Windows PC. It has not been run on a Db2 that was installed directly into a system, nor on a native Windows Db2, nor on AIX. The script uses no container-specific command. The only place that depends on the installation is found at run time: the install path comes from `db2level`.

---

## Install

### Linux (direct installation or container)

Copy this repository to the Db2 server. As the instance owner:

```bash
. ~/sqllib/db2profile            # skip if db2 already works in your shell
bash scripts/build_db.sh         # builds in this repository folder; or:  bash scripts/build_db.sh /path/to/folder
echo "exit code $?"
```

The folder must hold `ddl/`, `sql/` and `scripts/`. Logs go to `logs/` inside it. The script needs only `bash`, `db2` and the usual `sed`, `grep`, `awk` and `diff`.

What the build does:

| Step | What happens |
|---|---|
| 1 | Drops an existing `SAMPLE27` (force applications, deactivate, drop) and creates it: UTF-8, territory US, page size 8192 |
| 2 | Runs `ddl/sample27.ddl` |
| 3 | Runs `db2sampl -sql -xml -vector` into a temporary database `S27SRC`, exports its 25 tables with `db2move`, drops `S27SRC`, and `IMPORT`s the tables into `SAMPLE27` in foreign-key order. That is the data of the original `SAMPLE`, errors included; nothing is changed in this step. The three circular keys are set `NOT ENFORCED` during the load and enforced again afterwards |
| 4 | Changes to that data, each in its own file so that it can be read, skipped or run alone: `sql/data_fixes.sql` repairs impossible dates only. 4b `synthetic_data.sql` adds rows. 4c `xml_schemas.sql` registers the 4 XML schemas from the `.xsd` files of your Db2 install. 4d `resume_fixes.sql` makes résumé dates agree with `EMPLOYEE`. |
| 5 | `sql/checks.sql`: integrity queries, each must return 0 |
| 6 | Row counts against `sql/rowcounts.txt` |
| 7 | `sql/verify.sql`: objects, routines, triggers, constraints and their behaviour |
| 8 | Prints the instance licence |

The exit code is 0 only if every step and assertion passed. The last line is either
`RESULT: SAMPLE27 build OK - all steps and assertions passed` or `RESULT: SAMPLE27 build FAILED - n failure(s); see logs/`.

To remove it: `db2 force application all; db2 deactivate database SAMPLE27; db2 terminate; db2 drop database SAMPLE27`.

### Db2 in a container under Podman (Linux, macOS or Windows)

The build runs inside the container, as the instance owner. You copy the folder in and start the script, so the same four commands work in PowerShell, cmd, macOS and Linux shells. The Db2 container must be running and Db2 must be started in it. Replace `<your_db2_container_name>` with the name of your Db2 container (`podman ps` lists it). Run the commands from the folder that contains this repository folder, here called `db2-sample27`:

```
podman exec <your_db2_container_name> rm -rf /tmp/sample27_build
podman cp <this folder> <your_db2_container_name>:/tmp/sample27_build
podman exec <your_db2_container_name> chown -R db2inst1 /tmp/sample27_build
podman exec <your_db2_container_name> su - db2inst1 -c "bash /tmp/sample27_build/scripts/build_db.sh /tmp/sample27_build"
```

- The `rm` makes sure the target folder does not exist: copying into an existing folder would put the copy one level deeper. It prints nothing if the folder is not there.
- The `chown` is needed because the copy belongs to root and the build runs as `db2inst1`.
- The build takes a few minutes. The last line is `RESULT: SAMPLE27 build OK - all steps and assertions passed` or `RESULT: SAMPLE27 build FAILED - n failure(s); see logs/`.
- If a step fails with `No such file or directory` for a file under `sql/` or `ddl/`, the copy is incomplete or from another checkout. Check that `ddl/`, `sql/` and `scripts/` are in the folder you copied, and copy again.
- The logs are inside the container. To read them on the host: `podman cp <your_db2_container_name>:/tmp/sample27_build/logs ./logs_from_container`
- Clean up the copy when done: `podman exec <your_db2_container_name> rm -rf /tmp/sample27_build`. The database `SAMPLE27` stays in the container.

Later for testing, log into your Db2 container by enterring:
```
podman exec -it <your_db2_container_name> su - db2inst1
```

To remove the database:

```
podman exec <your_db2_container_name> su - db2inst1 -c "db2 force application all; db2 deactivate database SAMPLE27; db2 terminate; db2 drop database SAMPLE27"
```

**Podman connections.** If Podman talks to a Podman machine or a remote host, write `podman --connection <your_podman_machine_name> ...` in each command, or `podman --connection <your_podman_machine_root> ...` if the Db2 container runs in the machine's root (rootful) connection. `podman system connection ls` lists the names.

**Wrapper scripts.** `build_sample27.sh` and `uninstall_sample27.sh` do the same on a host with bash (Linux, macOS, or Git Bash or WSL on Windows). Set the environment variable `DB2_CONTAINER` to the name of your Db2 container, for example `DB2_CONTAINER=<your_db2_container_name> ./build_sample27.sh`. If it is not set, the scripts list the running containers and ask for the name; without a terminal (a pipeline, a scheduled job) they stop with a message instead. `PODMAN_CONNECTION` is optional: set it to `<your_podman_machine_name>` or `<your_podman_machine_root>` only if you use a Podman connection other than the default. The commands above need neither script.

### Install on Windows

The steps below are what `scripts/build_db.sh` does, written for the Db2 command window (`db2cmd`); work in the repository folder. The same statements, run in this order on Linux, finish with 0 errors in every step. They have not been run on Windows itself.

```
db2 "CREATE DATABASE SAMPLE27 USING CODESET UTF-8 TERRITORY US PAGESIZE 8192"
db2 -tvf ddl\sample27.ddl

rem the original sample data, from Db2 itself, in a temporary database
db2sampl -name S27SRC -sql -xml -vector -force
mkdir source
cd source
db2move S27SRC export -sn DB2INST1
cd ..
db2 force application all
db2 deactivate database S27SRC
db2 terminate
db2 drop database S27SRC

db2 -tvf sql\load_data.sql
db2 -tvf sql\data_fixes.sql
db2 -tvf sql\synthetic_data.sql
db2 -tvf sql\resume_fixes.sql
db2 -tvf sql\checks.sql
```

`sql/xml_schemas.sql` has the placeholder `@DB2PATH@` where the Db2 install path belongs. Replace it with the path shown by `db2level` ("Product is installed at"), save the file under another name, then run it with `db2 -tvf`.

The assertions of steps 5 to 7 are in `scripts/build_db.sh`; on Windows the `.sql` files run, but nothing counts the results for you. `sql/checks.sql` prints one line per check. Each must be 0, except two informational lines: `ACT row count` is 18 and `EMPLOYEE JOB longer than 3 chars` is 42.

---

## Testing steps, with examples

The examples use the `db2` command line (on Windows, a Db2 command window). For a query in a file, put `CONNECT TO SAMPLE27;` at the top and run it with `db2 -tf query.sql`; every query below ends with `;`. For a one-liner:

```bash
db2 +o connect to SAMPLE27 && db2 "SELECT COUNT(*) FROM DB2INST1.EMPLOYEE"
```

### 1. The build is the test

```bash
bash scripts/build_db.sh; echo "exit code $?"
```

Expect `exit code 0` and the `RESULT: ... build OK` line. The assertions are listed in the table above and in `scripts/build_db.sh`. All write tests inside the build are rolled back.

### 2. Count the objects

```sql
SELECT COUNT(*) AS TABLES FROM SYSCAT.TABLES WHERE TABSCHEMA = 'DB2INST1' AND TYPE = 'T';
```
```
TABLES
-----------
         25
```

Row counts per table are in [`sql/rowcounts.txt`](sql/rowcounts.txt) (for example `EMPLOYEE 42`, `SALES 41`, `EMPMDC 10000`, `PATIENTS 20`, `MLBLOGS_ANSWERS 108`). The build compares them with the loaded tables.

### 3. Summary table (MQT)

`ADEFUSR` stores the result of "employees per department", and Db2 keeps it current inside your transaction. It is read-only.

```sql
SELECT WORKDEPT, NO_OF_EMPLOYEES FROM DB2INST1.ADEFUSR ORDER BY 1 FETCH FIRST 3 ROWS ONLY;
```
```
WORKDEPT NO_OF_EMPLOYEES
-------- ---------------
A00                    5
B01                    1
C01                    4
```

### 4. Repaired dates

In the original, JONES was hired in 1998 and born in 2003. In SAMPLE27 the birth year moved back 30 years and the hire date stayed. NICHOLLS, who worked on a project five years before his hire date in the original, was hired in 2001 here.

```sql
SELECT EMPNO, FIRSTNME, LASTNAME, HIREDATE, BIRTHDATE
FROM   DB2INST1.EMPLOYEE WHERE LASTNAME IN ('JONES','NICHOLLS') ORDER BY LASTNAME;
```
```
EMPNO  FIRSTNME     LASTNAME        HIREDATE   BIRTHDATE
------ ------------ --------------- ---------- ----------
000210 WILLIAM      JONES           04/11/1998 02/23/1973
000140 HEATHER      NICHOLLS        12/15/2001 01/19/1976
```

No person works on a project before the hire date:

```sql
SELECT COUNT(*) FROM DB2INST1.EMPLOYEE E
WHERE EXISTS (SELECT 1 FROM DB2INST1.EMPPROJACT A WHERE A.EMPNO = E.EMPNO AND A.EMSTDATE < E.HIREDATE);
```
```
0
```

### 5. XML with XQuery

```sql
SELECT XMLCAST(XMLQUERY('$d/customerinfo/name' PASSING INFO AS "d") AS VARCHAR(40)) AS NAME
FROM   DB2INST1.CUSTOMER ORDER BY CID FETCH FIRST 3 ROWS ONLY;
```
```
NAME
----------------------------------------
Kathy Smith
Kathy Smith
Jim Noodle
```

### 6. Vector similarity

The five nearest patients to patient 6 (57, female, smoker), by cosine distance on the shipped embeddings (shown multiplied by one million, so only the order matters). There is no vector index, so every row is compared:

```sql
SELECT P.PATIENT_ID, P.AGE, P.GENDER, P.SMOKING_STATUS,
       DEC(VECTOR_DISTANCE(P.EMBEDDING, T.EMBEDDING, COSINE) * 1000000, 8, 1) AS DIST_E6
FROM   DB2INST1.PATIENTS P
CROSS JOIN (SELECT EMBEDDING FROM DB2INST1.PATIENTS WHERE PATIENT_ID = 6) T
WHERE  P.PATIENT_ID <> 6
ORDER BY VECTOR_DISTANCE(P.EMBEDDING, T.EMBEDDING, COSINE) FETCH FIRST 3 ROWS ONLY;
```
```
PATIENT_ID  AGE         GENDER SMOKING_STATUS DIST_E6
----------- ----------- ------ -------------- ----------
         16          56 Female Smoker               39.9
         12          76 Female Smoker               47.3
         15          64 Female Smoker               62.2
```

More examples: [`sql/vector_examples.sql`](sql/vector_examples.sql).

### 7. Double-byte text

`STAFFG` is the double-byte twin of `STAFF` (`VARGRAPHIC` and `GRAPHIC` columns, UTF-16 in a Unicode database). The content is plain Latin text:

```sql
SELECT NAME, JOB FROM DB2INST1.STAFFG WHERE ID IN (10, 20);
```
```
NAME               JOB
------------------ ----------
Sanders            Mgr
Pernal             Sales
```

### 8. A Db2 sample program

Build and run the embedded-C sample `tbread` against `SAMPLE27`. Copy `bldapp`, `embprep`, `utilemb.sqc`, `utilemb.h`, `utilapi.c`, `utilapi.h` and `tbread.sqc` from `sqllib/samples/c` into an empty directory first; `bldapp` needs `embprep` and the util files next to it:

```bash
./bldapp tbread SAMPLE27 <user> <password>    # precompile, bind, compile, link
./tbread SAMPLE27 <user> <password>           # exit code 0
```

The start of its output:

```
  Connecting to 'SAMPLE27' database...
  Connected to 'SAMPLE27' database.
  Perform:
    SELECT deptnumb, deptname FROM org

  Results:
    DEPTNUMB DEPTNAME
    -------- --------------
          10 Head Office
          15 New England
          20 Mid Atlantic
```

The XML sample script from `sqllib/samples/xml/clp`, with the database name changed (`CONNECT TO sample;` becomes `CONNECT TO sample27;`):

```bash
db2 -tvf xmlinsert.db2 > out.txt; grep -E "^SQL[0-9]+N" out.txt
```
```
SQL16203N  XML document input ended before all started tags were ended. ...
```

That one error is intended: the script inserts a broken document on purpose, and it deletes its own rows afterwards.

---

## Compatibility with the Db2 sample programs

`SAMPLE` exists for the programs that Db2 ships under `sqllib/samples`. Counted from file names, there are 431 source files in 257 distinct demos (the same demo in several languages is counted once; the exact list is in [`presentation/sample_programs.md`](presentation/sample_programs.md)).

**What was tested on SAMPLE27**

| Program | Result |
|---|---|
| `tbread` (embedded C: reads tables) | Precompiles, binds, builds and runs with exit code 0 against `SAMPLE27` |
| `xmlinsert.db2` (CLP script) | Runs to the end with exactly one error, `SQL16203N`, which is the one it provokes on purpose; it cleans up after itself |
| `tbmod`, `tbtrig`, `tbintrig`, `tbconstr`, `dtlob`, `dbuse` | Tested on SAMPLE27 (offline backup first, one program at a time, row counts and sums of 9 tables compared before and after): nothing left behind; the foreign keys the rebuild added did not break them. `tbconstr` reports its own expected error |
| `xupdate.db2` | Works, but leaves purchase order 5012 behind. A data-changing script changes order counts |

The backup was restored afterwards and the state matched the state before.

**Not tested:** the rest of the 257 demos. In particular, nothing was run for the roughly 40 programs that mention `STAFF` beyond `tbread`, `tbmod` and `tbtrig`, nor for the `DO_NOT_DEL_SALES` trigger from those programs. Treat the list above as what is known, not as a guarantee.

**What can make a program behave differently from the same program on `SAMPLE`**

| Difference | Effect |
|---|---|
| The database is called `SAMPLE27` | Programs that take the database name as an argument work. A program with `sample` hard-coded needs changing. `xmlinsert.db2` has `CONNECT TO sample;` in it |
| Surrogate keys on four tables | `SALES`, `IN_TRAY`, `MLBLOGS_QUESTIONS` and `MLBLOGS_ANSWERS` have a new first column (`SALES_ID`, `TRAY_ID`, `QUESTION_ID`, `ANSWER_ID`), `GENERATED ALWAYS AS IDENTITY`. `SELECT *` returns one more column. An `INSERT` without a column list must name the columns |
| `STAFF.SALARY` and `STAFF.COMM` are `DECIMAL(9,2)` | In the original they are `DECIMAL(7,2)`, which caps a salary at 99,999.99. On a fresh original with the same change, `tbread`, `tbmod` and `tbtrig` built, ran and left the same 35 rows and the same salary total, and the `MIN_SALARY` trigger still worked. A program that declares its host variable with 7 digits needs a wider one for large values. Changing the type needs a `REORG` |
| Repaired dates | 15 hire dates moved back by whole years, 4 birth years moved back 30 years, 3 project end dates moved forward 20 years, 4 résumés corrected. Employee numbers and names are unchanged, so programs that name rows by key (000130, 000140, 000050; Sanders, Wheeler, Hanes) find the same rows; only the dates inside them differ |
| More foreign keys | 16 instead of 12. Deleting a parent row that has children now fails with `SQL0530N` or cascades, depending on the key, where the original silently allowed it |
| Extra rows | See [Synthetic rows](#synthetic-rows): programs that count rows in the affected tables see more |
| XML schema repository | The 4 schemas (`CUSTOMER`, `PORDER`, `PRODUCT`, `SUPPLIER`) are registered, as in the original. Without them `xmlinsert.db2` fails earlier with `SQL0204N` |
| Vector indexes | Not available on these tables. See below |

**Vector indexes.** `CREATE VECTOR INDEX` is supported on Linux on AMD64 only. The shipped vector columns are `VECTOR(768)` and `VECTOR(1024)` in an 8 KB tablespace; an 8 KB page allows 512 `FLOAT32` dimensions, so the index is rejected with `SQL0614N`. On an Apple-silicon Mac (x86-64 Db2 under emulation) creating one also crashed the instance, even for 4 dimensions. The cause was not found. Whether an index works on real x86-64 Linux has not been tried.

---

## What was wrong with SAMPLE, and what SAMPLE27 changes

**SAMPLE as a script.** The `db2look` export of the original SAMPLE database (this repository does not contain it; make it with `db2look -d SAMPLE -e -o sample.ddl`, 1,236 lines in the test), run on an empty 12.1.5 database:

| | |
|---|---|
| SQL errors | **45** (43 × `SQL0204N`, 2 × `SQL0104N`) |
| Tables created | 14 of 25 |
| Views created | 4 of 19 |
| Triggers created | 1 of 2 |

Causes:
- **Missing tablespaces.** `IBMDB2SAMPLEREL`, `IBMDB2SAMPLEXML` and `IBMDB2SAMPLEVECTOR` are used but not created, because the export was made without `db2look -l`. An export made with `db2look -l` contains them, but they only succeed in a database with an 8 KB page size.
- **Wrong order.** Views come before the aliases (`DEPT`, `EMP`, `PROJ`) they use.
- **Circular keys.** `DEPARTMENT` and `EMPLOYEE` reference each other, plus self-references.
- **CLP parsing.** The body of the trigger `do_not_del_sales` is cut at an inner `;`.
- **Noise.** 67 repeated `SET SCHEMA`, `SET PATH` and `NLS_STRING_UNITS` statements.

**SAMPLE as data**

| Finding | In SAMPLE | In SAMPLE27 |
|---|---|---|
| Primary keys | 11 of 25 tables had none | All 25 have one (natural keys where the data has one, identity columns on four tables) |
| Foreign keys | 12, one of them broken (`ACT` → `ACT`) | 16; broken key replaced; 4 added where the data already obeyed the rule (no orphans) |
| Check constraints | 1 | 5 (date ranges of projects and assignments) |
| Impossible dates | Hired before born (1 person), hired as a toddler (3), two hired under 18, 3 projects ending 20 years before they start, 15 people with assignments before the hire date | Repaired. Nobody works before the hire date, and nobody is hired under 18 |
| Résumés | Birth and hire dates 30 years older than `EMPLOYEE` | Dates inside the text agree with `EMPLOYEE`; the fixed-width layout is kept |
| Routine bugs | `resign_employee` returns the job in the department column; `bonus_increase` swallows unexpected SQL errors | Returns the department; sets `p_errorMsg` with the SQLSTATE |
| Duplicate constraint name | `PK_PRODUCTSUPPLIER` on two tables | `SUPPLIERS` key renamed `PK_SUPPLIERS` |
| XML schema repository | 4 schemas registered | Registered again by `sql/xml_schemas.sql` |
| Unused sequence | `SAMPSEQUENCE` | Feeds `PURCHASEORDER.POID` |

**Left as in the original, on purpose:** column types (`EMPNO CHAR(6)`, small integer keys, `PRODUCT.PRICE DECIMAL(30,2)`), legacy names (`FIRSTNME`), the compatibility aliases, `STAFFG`, the old dates, the 1988 mail whose senders were hired years later, and `STAFF.YEARS`. The one exception is the widened `STAFF.SALARY` and `STAFF.COMM`.

**The layers of SAMPLE** (what `db2sampl` creates):

| Flag | Tables | Tablespace |
|---|---|---|
| `-sql` | 15 (14 core tables and the MDC table `EMPMDC`), plus the MQT `ADEFUSR`, 19 views, 5 aliases, 2 triggers, 2 routines, 1 sequence, 11 foreign keys | `IBMDB2SAMPLEREL` |
| `-xml` | 7 (`PRODUCT`, `CUSTOMER`, `PURCHASEORDER`, `CATALOG`, `SUPPLIERS`, `INVENTORY`, `PRODUCTSUPPLIER`), 6 XML columns, 4 registered XML schemas | `IBMDB2SAMPLEXML` |
| `-vector` | 3 (`PATIENTS`, `MLBLOGS_QUESTIONS`, `MLBLOGS_ANSWERS`) | `IBMDB2SAMPLEVECTOR` |
| none | all three; identical row counts | all three |

`db2sampl -v8` is a separate, older sample (12 tables, no views, triggers or routines) and cannot be combined with the others.

**Does MDC pay off here?** Not at this size. At 10,000 rows `EMPMDC` takes about 7 times the space of a plain copy and is not faster.
With a million rows, a query on one dimension took 16–19 ms against about 80 ms for a plain table with an index.

---

## Synthetic rows

These rows do not exist in the original `SAMPLE`. They are added by `sql/synthetic_data.sql` so that every foreign key SAMPLE27 added has real parent and child rows to be tested with:

| Table | Added |
|---|---|
| `PROJACT` | Activity 120 for project `PL2100` |
| `EMPPROJACT` | 3 assignments in `PL2100` for employees who had none: 200120, 200170, 200220 (their hire dates move back by whole years, the same rule as in `data_fixes.sql`) |
| `PRODUCT` and `INVENTORY` | 2 products with stock |
| `SUPPLIERS` and `PRODUCTSUPPLIER` | 1 supplier (102) and 4 product-supplier pairs, one product with two suppliers |
| `PURCHASEORDER` | 2 orders whose `POID` comes from `SAMPSEQUENCE`, which starts at 5007, above the loaded orders |

Compared with a default `db2sampl` run, SAMPLE27 therefore has more rows in 7 tables: `EMPPROJACT` (76 against 73), `PROJACT` (66 against 65) and the five XML tables. The leavers are deliberately given no assignments.

---

## Repository layout

| Path | Content |
|---|---|
| `ddl/sample27.ddl` | The schema |
| `sql/` | Data load for manual use (`load_data.sql`), `rowcounts.txt`, data fixes, synthetic data, XML schemas, résumé fixes, optional embeddings, integrity checks and verification, vector examples |
| `scripts/build_db.sh` | The build (Linux, bash); runs on the Db2 server as the instance owner |
| `build_sample27.sh`, `uninstall_sample27.sh` | Wrappers for a Db2 under Podman |
| `logs/` | Logs written by the build |
| `presentation/` | A slide deck with the full findings, and the list of Db2 sample programs |

---

## Licence and attribution

**This repository is not under an open-source licence.** The terms are in [`LICENSE`](LICENSE). In short:

- You may use, copy, modify and distribute the files that the author wrote, free of charge, for any purpose.
- If you make a use public, or pass a copy or a derived work to someone else, you must name the author and keep the licence and the copyright notices. A line such as this is enough: **Based on SAMPLE27 by Marcin Paluch.**
- Private use, to test or learn, needs no mention.
- There is no warranty. The scripts drop and recreate a database.

**What the licence does not cover.** SAMPLE27 is derived from the Db2 `SAMPLE` database. Its original schema, table names and data, and IBM's sample programs, stay under IBM's terms. Db2 is a trademark of IBM. This repository is not affiliated with or endorsed by IBM.

**Db2 editions.** SAMPLE27 needs no licence of its own from IBM beyond the Db2 licence of whoever runs it; the build was checked on Db2 Community Edition, where `db2licm` reports it in compliance with the summary table and the MDC table present. Other editions should work, with one exception that IBM documents for `db2sampl`: on Db2 Workgroup Server Edition the SAMPLE database contains materialized query tables and multidimensional clustering tables, which IBM says cause a licence violation that only an upgrade to Enterprise Server Edition removes. SAMPLE27 keeps both (`ADEFUSR` and `EMPMDC`), so the same applies there. This is a reading of the documentation, not legal advice.
