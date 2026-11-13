#!/bin/bash
# =====================================================================
# SAMPLE27 - build script. Runs on the Db2 server, as the instance owner,
# for any Db2 12.1.5 LUW installation on Linux: installed directly into the system or run
# in a container. The only things it needs are bash, the db2 command line and the files
# of this repository.
#
# Copyright (c) 2026 Marcin Paluch. All rights reserved.
#
# Drops and recreates database SAMPLE27:
#   ddl/sample27.ddl  ->  the original sample data, taken from Db2 itself (db2sampl into a
#   temporary database, exported with db2move, imported)  ->  sql/data_fixes.sql
#   ->  sql/synthetic_data.sql  ->  sql/checks.sql  ->  sql/verify.sql
# This repository contains no data of the original SAMPLE database.
#
#   bash scripts/build_db.sh [directory]      directory = the repository folder (default: this one)
#
# Environment:
#   The db2 command and db2sampl must work in this shell: as the instance owner, with the instance profile
#   loaded (on Linux:  . ~/sqllib/db2profile).
# Exit code 0 = every step and every assertion passed.
# =====================================================================

B=${1:-$(cd "$(dirname "$0")/.." && pwd)}
DB=SAMPLE27
LOG=$B/logs
FAILS=0

command -v db2 >/dev/null 2>&1 || { echo "db2 command not found: run this as the instance owner after '. ~/sqllib/db2profile'"; exit 98; }
mkdir -p "$LOG"
cd "$B" || exit 99

# where this Db2 is installed: the XML schema files of step 4c are in <install>/samples/db2sampl
DB2PATH=$(db2level 2>/dev/null | sed -n 's/.*installed at "\(.*\)".*/\1/p' | head -1)

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAILS=$((FAILS+1)); }
step() { echo; echo "== $1"; }

# --- 1. drop and create ------------------------------------------------
step "1. Drop and create database $DB"
db2 terminate >/dev/null 2>&1
if db2 list db directory 2>/dev/null | grep -qi "Database name *= $DB\$"; then
  # an activated database cannot be dropped (SQL1035N): disconnect everyone, deactivate, then drop
  db2 force application all >/dev/null 2>&1
  sleep 2
  db2 deactivate database $DB >/dev/null 2>&1
  db2 terminate >/dev/null 2>&1
  db2 drop database $DB > "$LOG/01_drop.log" 2>&1 && pass "dropped existing $DB" || fail "drop $DB"
else
  pass "no existing $DB"
fi
db2 "CREATE DATABASE $DB USING CODESET UTF-8 TERRITORY US PAGESIZE 8192" > "$LOG/02_create.log" 2>&1 \
  && pass "created $DB (UTF-8, pagesize 8192)" || fail "create $DB"

# --- 2. schema ---------------------------------------------------------
step "2. Run ddl/sample27.ddl"
db2 -tvf ddl/sample27.ddl > "$LOG/03_ddl.log" 2>&1
n=$(grep -cE 'SQL[0-9]+N' "$LOG/03_ddl.log")
[ "$n" = 0 ] && pass "DDL ran with 0 errors" || fail "DDL produced $n errors (see logs/03_ddl.log)"

# --- 3. data load: the original sample data comes from Db2 itself -------------------
SRCDB=S27SRC
SRC=$LOG/source
step "3. Create the original sample data with db2sampl ($SRCDB, temporary) and import it"
db2 terminate >/dev/null 2>&1
db2sampl -name $SRCDB -sql -xml -vector -force > "$LOG/03a_db2sampl.log" 2>&1 \
  && pass "db2sampl created temporary database $SRCDB" || fail "db2sampl failed (see logs/03a_db2sampl.log)"
rm -rf "$SRC"; mkdir -p "$SRC"
( cd "$SRC" && db2move $SRCDB export -sn DB2INST1 > "$LOG/03b_db2move_export.log" 2>&1 )
[ "$(grep -c . "$SRC/db2move.lst" 2>/dev/null)" = 25 ] && pass "exported the 25 tables of $SRCDB" || fail "db2move export did not produce 25 tables (see logs/03b_db2move_export.log)"
db2 force application all >/dev/null 2>&1; sleep 2
db2 deactivate database $SRCDB >/dev/null 2>&1; db2 terminate >/dev/null 2>&1
db2 drop database $SRCDB > "$LOG/03c_drop_source.log" 2>&1 && pass "dropped temporary database $SRCDB" || fail "drop $SRCDB"
{
  echo "CONNECT TO $DB;"
  # circular / self references are relaxed while loading, then re-enforced (and validated)
  echo "ALTER TABLE DB2INST1.DEPARTMENT ALTER FOREIGN KEY RDE NOT ENFORCED;"
  echo "ALTER TABLE DB2INST1.DEPARTMENT ALTER FOREIGN KEY ROD NOT ENFORCED;"
  echo "ALTER TABLE DB2INST1.PROJECT ALTER FOREIGN KEY RPP NOT ENFORCED;"
  for t in ACT DEPARTMENT EMPLOYEE EMP_PHOTO EMP_RESUME PROJECT PROJACT EMPPROJACT \
           CL_SCHED IN_TRAY ORG STAFF SALES STAFFG EMPMDC PRODUCT INVENTORY CUSTOMER \
           PURCHASEORDER CATALOG SUPPLIERS PRODUCTSUPPLIER PATIENTS \
           MLBLOGS_QUESTIONS MLBLOGS_ANSWERS; do
    f=$(grep "\"$t\"" "$SRC/db2move.lst" | head -1 | cut -d'!' -f3)
    # tables that got a generated surrogate key in SAMPLE27 need an explicit column list
    # (the original tables do not have that column)
    case "$t" in
      IN_TRAY)           cols="(RECEIVED, SOURCE, SUBJECT, NOTE_TEXT)" ;;
      SALES)             cols="(SALES_DATE, SALES_PERSON, REGION, SALES)" ;;
      MLBLOGS_QUESTIONS) cols="(QUESTION, EMBEDDING)" ;;
      MLBLOGS_ANSWERS)   cols="(ANSWER, EMBEDDING)" ;;
      *)                 cols="" ;;
    esac
    echo "IMPORT FROM $SRC/$f OF IXF LOBS FROM $SRC XML FROM $SRC MESSAGES $LOG/imp_$t.txt INSERT INTO DB2INST1.$t $cols;"
  done
  echo "ALTER TABLE DB2INST1.DEPARTMENT ALTER FOREIGN KEY RDE ENFORCED;"
  echo "ALTER TABLE DB2INST1.DEPARTMENT ALTER FOREIGN KEY ROD ENFORCED;"
  echo "ALTER TABLE DB2INST1.PROJECT ALTER FOREIGN KEY RPP ENFORCED;"
  echo "CONNECT RESET;"
} > "$LOG/load.sql"
db2 -tf "$LOG/load.sql" > "$LOG/04_load.log" 2>&1
n=$(grep -E 'SQL[0-9]+N' "$LOG/04_load.log" | grep -vc 'SQL3')
[ "$n" = 0 ] && pass "load statements ran with 0 errors" || fail "load produced $n errors (see logs/04_load.log)"
rej=0
for f in "$LOG"/imp_*.txt; do
  r=$(grep -A2 SQL3149N "$f" | tr -s ' \n' ' ' | sed -E 's/.*"([0-9]+)" rows were rejected.*/\1/')
  case "$r" in ''|*[!0-9]*) r=0;; esac
  rej=$((rej+r))
done
[ "$rej" = 0 ] && pass "0 rows rejected across 25 tables" || fail "$rej rows rejected"
rm -rf "$SRC"

# --- 4. repair of impossible dates (the original dates are kept) -----------------------------------
step "4. Run sql/data_fixes.sql (impossible dates only)"
db2 -tvf sql/data_fixes.sql > "$LOG/05_data_fixes.log" 2>&1
n=$(grep -cE 'SQL[0-9]+N' "$LOG/05_data_fixes.log")
[ "$n" = 0 ] && pass "data fixes ran with 0 errors" || fail "data fixes produced $n errors"

# --- 4b. synthetic data -------------------------------------------------------
step "4b. Run sql/synthetic_data.sql"
db2 -tvf sql/synthetic_data.sql > "$LOG/05b_synthetic_data.log" 2>&1
n=$(grep -cE 'SQL[0-9]+N' "$LOG/05b_synthetic_data.log")
[ "$n" = 0 ] && pass "synthetic data ran with 0 errors" || fail "synthetic data produced $n errors (see logs/05b_synthetic_data.log)"

# --- 4c. XML schema repository -----------------------------------------------
step "4c. Run sql/xml_schemas.sql (4 XML schemas, as in the original)"
sed "s#@DB2PATH@#$DB2PATH#g" sql/xml_schemas.sql > "$LOG/xml_schemas_run.sql"
db2 -tvf "$LOG/xml_schemas_run.sql" > "$LOG/05c_xml_schemas.log" 2>&1
n=$(grep -cE 'SQL[0-9]+N' "$LOG/05c_xml_schemas.log")
x=$(db2 connect to SAMPLE27 >/dev/null; db2 -x "select count(*) from syscat.xsrobjects" | tr -d ' '; db2 connect reset >/dev/null)
[ "$n" = 0 ] && [ "$x" = 4 ] && pass "4 XML schemas registered" || fail "XML schema registration: $n errors, $x registered (see logs/05c_xml_schemas.log)"

# --- 4d. believable resume dates -------------------------------------------------
step "4d. Run sql/resume_fixes.sql (resume dates agree with EMPLOYEE, old-school layout kept)"
db2 -tvf sql/resume_fixes.sql > "$LOG/05d_resume_fixes.log" 2>&1
n=$(grep -cE 'SQL[0-9]+N' "$LOG/05d_resume_fixes.log")
m=$(grep -c 'RESUME_CHECK' "$LOG/05d_resume_fixes.log")
[ "$n" = 0 ] && [ "$m" -le 1 ] && pass "resume dates fixed, 0 mismatches" || fail "resume fixes: $n errors, mismatch lines $m (see logs/05d_resume_fixes.log)"

# --- 5. integrity checks ------------------------------------------------------
step "5. Run sql/checks.sql"
db2 -x -tf sql/checks.sql > "$LOG/06_checks_result.txt" 2>&1
bad=0
while IFS= read -r line; do
  val=${line##* }
  case "$val" in ''|*[!0-9]*) continue;; esac
  name=$(echo "${line% *}" | sed 's/ *$//')
  case "$name" in
    "EMPLOYEE JOB longer than 3 chars") exp=42 ;;   # informational: JOB is CHAR(8)
    "ACT row count")                    exp=18 ;;
    *)                                  exp=0  ;;
  esac
  if [ "$val" != "$exp" ]; then echo "  FAIL  check '$name' = $val (expected $exp)"; bad=$((bad+1)); fi
done < "$LOG/06_checks_result.txt"
[ "$bad" = 0 ] && pass "all integrity checks as expected" || FAILS=$((FAILS+bad))

# --- 6. row counts versus the snapshot -----------------------------------------
step "6. Row counts versus sql/rowcounts.txt"
{
  echo "CONNECT TO $DB;"
  while read -r t c; do echo "SELECT '$t ' || RTRIM(CHAR(COUNT(*))) FROM DB2INST1.$t;"; done < sql/rowcounts.txt
  echo "CONNECT RESET;"
} > "$LOG/rowcounts.sql"
db2 -x -tf "$LOG/rowcounts.sql" 2>/dev/null | grep -E '^[A-Z_]+ [0-9]+' | sed 's/ *$//' > "$LOG/07_rowcounts_actual.txt"
if diff -q sql/rowcounts.txt "$LOG/07_rowcounts_actual.txt" >/dev/null; then
  pass "all 25 tables have the expected row counts"
else
  fail "row count mismatch:"; diff sql/rowcounts.txt "$LOG/07_rowcounts_actual.txt"
fi

# --- 7. object counts, behaviour tests -------------------------------------------
step "7. Run sql/verify.sql (objects, routines, triggers, constraints)"
db2 +c -tvf sql/verify.sql > "$LOG/08_verify.log" 2>&1
v=$LOG/08_verify.log
chk() { grep -q "$2" "$v" && pass "$1" || fail "$1"; }
chk "25 base tables + 1 MQT"                "OBJ_TABLES=25 MQT=1"
chk "19 views, 5 aliases"                   "OBJ_VIEWS=19 ALIASES=5"
chk "2 triggers, bonus_increase + resign_employee present" "OBJ_TRIGGERS=2 ROUTINES=2"
chk "no invalid objects"                    "INVALID=0"
chk "PURCHASEORDER relational and XML order dates agree" "PO_DATE_MISMATCH=0"
chk "ADEFUSR summary table populated"       "ADEFUSR_ROWS=ok"
chk "trigger do_not_del_sales blocks deleting Sales staff" "SQL0438N"
chk "trigger min_salary lifts Clerk salary to 10000" "MIN_SALARY_OK"
chk "resign_employee returns salary and department (E21)" "RESIGN_OK"
chk "resign_employee rolled back (42 employees remain)" "EMP_AFTER_ROLLBACK=42"
chk "bonus_increase rejects factor 5 with E01"       "E01 Checking parameter"
chk "RPAA: unknown activity rejected (SQL0530N)"        'RPAA'
chk "FK_INVENTORY_PROD: unknown product rejected"       'FK_INVENTORY_PROD'
chk "FK_PRODSUPP_PROD: unknown product rejected"        'FK_PRODSUPP_PROD'
chk "FK_PRODSUPP_SUPP: unknown supplier rejected"       'FK_PRODSUPP_SUPP'
chk "FK_EMPPROJACT_EMP: unknown employee rejected"      'FK_EMPPROJACT_EMP'
[ "$(grep -c 'SQL0530N' "$v")" = 5 ] && pass "5 inserts without a parent rejected (5 x SQL0530N)" \
  || fail "expected exactly 5 x SQL0530N, got $(grep -c 'SQL0530N' "$v")"
chk "FK_EMPPROJACT_EMP is RESTRICT: employee with assignments cannot be deleted (SQL0532N)" "SQL0532N"
chk "ON DELETE CASCADE removes stock and supplier links with a product" "CASCADE_PRODUCT_OK"
chk "ON DELETE CASCADE removes only that supplier's links"             "CASCADE_SUPPLIER_OK"
chk "cascade tests rolled back (INVENTORY 6, PRODUCTSUPPLIER 6)"       "CASCADE_ROLLED_BACK_OK"
chk "SAMPSEQUENCE supplies the POIDs of the synthetic orders (5007, 5008)" "SEQ_PO_OK"
chk "11 primary keys added in SAMPLE27 exist"         "PK_ADDED=11"
chk "every base table now has a primary key"          "TABLES_WITHOUT_PK=0"
chk "surrogate keys numbered from the load (SALES 41 rows)" "SURROGATE_OK"
[ "$(grep -c 'SQL0803N' "$v")" = 2 ] && pass "duplicate STAFF.ID and duplicate EMPPROJACT key both rejected (2 x SQL0803N)" \
  || fail "expected exactly 2 x SQL0803N (STAFF, EMPPROJACT), got $(grep -c 'SQL0803N' "$v")"
chk "new SALES row gets a generated id above the loaded ones" "NEW_SALES_ID_OK"
chk "NULL PATIENTS.PATIENT_ID rejected (SQL0407N)"    "SQL0407N"

# --- 8. license / edition ------------------------------------------------------------
step "8. Instance license"
db2licm -l 2>&1 | grep -E 'Product name|License type|Max amount|Max number|Enforcement' > "$LOG/09_license.txt"
cat "$LOG/09_license.txt" | sed 's/^/  /'

echo
if [ "$FAILS" = 0 ]; then echo "RESULT: SAMPLE27 build OK - all steps and assertions passed"; exit 0
else echo "RESULT: SAMPLE27 build FAILED - $FAILS failure(s); see logs/"; exit 1; fi
