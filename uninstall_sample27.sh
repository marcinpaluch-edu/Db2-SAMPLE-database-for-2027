#!/bin/bash
# =====================================================================
# SAMPLE27 - complete uninstall, run on the host of a Db2 container under Podman
#
# Copyright (c) 2026 Marcin Paluch. All rights reserved.
#
# Removes database SAMPLE27 (and everything that was added to it, such as the talk2data layers):
#   FORCE APPLICATION ALL -> DEACTIVATE DATABASE -> TERMINATE -> DROP DATABASE -> verify gone
# An activated database cannot be dropped (SQL1035N), hence the DEACTIVATE.
# The Db2 container and the other databases are not touched.
#
#   DB2_CONTAINER=<your_db2_container_name> ./uninstall_sample27.sh
#
# Environment:  DB2_CONTAINER (podman ps): if not set, the script lists the running containers and asks for the name
#               (without a terminal, e.g. in a pipeline, it stops instead);  PODMAN_CONNECTION optional (podman system connection ls)
# =====================================================================

CT=${DB2_CONTAINER:-}
CONN=${PODMAN_CONNECTION:-}
if [ -z "$CT" ] && [ -t 0 ]; then
  echo "DB2_CONTAINER is not set. Running containers:"; { if [ -n "$CONN" ]; then podman -c "$CONN" ps --format '  {{.Names}}'; else podman ps --format '  {{.Names}}'; fi; } 2>/dev/null
  read -r -p "Name of your Db2 container: " CT
fi
[ -n "$CT" ] || { echo "Set DB2_CONTAINER to the name of your Db2 container (podman ps), e.g.  DB2_CONTAINER=<your_db2_container_name> $0"; exit 2; }
pm() { if [ -n "$CONN" ]; then podman -c "$CONN" "$@"; else podman "$@"; fi; }

OUT=$(pm exec "$CT" su - db2inst1 -c '
  if ! db2 list db directory | grep -qi "Database name *= SAMPLE27$"; then echo "NOT_CATALOGUED"; exit 0; fi
  db2 force application all >/dev/null 2>&1; sleep 2
  db2 deactivate database SAMPLE27 2>&1 | grep -E "SQL|DB200" 
  db2 terminate >/dev/null 2>&1
  db2 drop database SAMPLE27 2>&1 | grep -E "SQL|DB200"
  if db2 list db directory | grep -qi "Database name *= SAMPLE27$"; then echo "STILL_THERE"; else echo "GONE"; fi
' 2>&1)
echo "$OUT"
case "$OUT" in
  *GONE*)          echo "UNINSTALL OK: SAMPLE27 dropped"; exit 0 ;;
  *NOT_CATALOGUED*) echo "UNINSTALL OK: SAMPLE27 was not installed"; exit 0 ;;
  *)               echo "UNINSTALL FAILED: see messages above"; exit 1 ;;
esac
