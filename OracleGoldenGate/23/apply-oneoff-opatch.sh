#!/bin/bash
set -euo pipefail

PATCH_ZIP="$1"

export ORACLE_HOME=/u01/ogg
export PATH=$ORACLE_HOME/OPatch:$ORACLE_HOME/bin:$PATH

run_as_ogg() {
    local uid gid
    uid="$(id -u ogg)"
    gid="$(id -g ogg)"

    setpriv \
      --reuid "$uid" \
      --regid "$gid" \
      --clear-groups \
      "$@"
}

echo "Applying one-off patch: $PATCH_ZIP"

WORKDIR=$(mktemp -d)
unzip -q "$PATCH_ZIP" -d "$WORKDIR"
chown -R ogg:ogg "$WORKDIR"
# Oracle one-off patches always unzip to <PATCH_NUMBER>/
PATCH_DIR="$(ls -d "$WORKDIR"/* | head -n 1)"

echo "Entering patch directory: $PATCH_DIR"
cd "$PATCH_DIR"

run_as_ogg opatch apply -silent
run_as_ogg opatch lsinventory

rm -rf "$WORKDIR" "$PATCH_ZIP"

echo "One-off patch applied successfully"

