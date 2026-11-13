#!/bin/bash
# =====================================================================
# SAMPLE27 - one-command build, run on the host of a Db2 container under Podman
#
# Copyright (c) 2026 Marcin Paluch. All rights reserved.
#
# Copies this folder into the Db2 container, then (as db2inst1) drops and
# recreates database SAMPLE27 from ddl/ and sql/, and verifies it.
# Logs are copied back to ./logs.
#
#   DB2_CONTAINER=<your_db2_container_name> ./build_sample27.sh
#
# Environment:
#   DB2_CONTAINER      name of the Db2 container (podman ps). If not set, the script lists the running
#                      containers and asks for the name (without a terminal, e.g. in a pipeline, it stops instead)
#   PODMAN_CONNECTION  optional: Podman connection name (podman system connection ls)
# =====================================================================

CT=${DB2_CONTAINER:-}
CONN=${PODMAN_CONNECTION:-}
if [ -z "$CT" ] && [ -t 0 ]; then
  echo "DB2_CONTAINER is not set. Running containers:"; { if [ -n "$CONN" ]; then podman -c "$CONN" ps --format '  {{.Names}}'; else podman ps --format '  {{.Names}}'; fi; } 2>/dev/null
  read -r -p "Name of your Db2 container: " CT
fi
[ -n "$CT" ] || { echo "Set DB2_CONTAINER to the name of your Db2 container (podman ps), e.g.  DB2_CONTAINER=<your_db2_container_name> $0"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST=/tmp/sample27_build

pm() { if [ -n "$CONN" ]; then podman -c "$CONN" "$@"; else podman "$@"; fi; }

pm exec "$CT" rm -rf "$DEST" || exit 1
pm cp "$HERE" "$CT:$DEST" || exit 1
pm exec "$CT" chown -R db2inst1 "$DEST" || exit 1

pm exec "$CT" su - db2inst1 -c "bash $DEST/scripts/build_db.sh $DEST"
RC=$?

mkdir -p "$HERE/logs"
pm cp "$CT:$DEST/logs/." "$HERE/logs/" 2>/dev/null
pm exec "$CT" rm -rf "$DEST"

echo
echo "Logs: $HERE/logs   (exit code $RC)"
exit $RC
