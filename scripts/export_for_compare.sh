#!/bin/bash
# Exports the 25 DB2INST1 base tables of a database to DEL files (LOBs and XML to side files), for comparing two builds with diff -r.
#   bash scripts/export_for_compare.sh DATABASE OUTDIR
DBN=$1; OUT=$2
rm -rf "$OUT"; mkdir -p "$OUT"
export DB2DBDFT="$DBN"
for t in $(db2 -x "select rtrim(tabname) from syscat.tables where tabschema='DB2INST1' and type='T' order by 1"); do
  cols=$(db2 -x "select rtrim(colname) from syscat.columns where tabschema='DB2INST1' and tabname='$t' and identity='N' and generated=' ' order by colno" | paste -sd, -)
  db2 "export to $OUT/$t.del of del lobs to $OUT/ lobfile ${t}_ xml to $OUT/ xmlfile ${t}_ select $cols from DB2INST1.$t order by 1,2" > "$OUT/$t.msg" 2>&1 || echo "export $t failed"
  grep -E "SQL[0-9]+N" "$OUT/$t.msg" | head -2
done

