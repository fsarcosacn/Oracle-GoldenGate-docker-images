#!/bin/bash
set -euo pipefail

OPATCH_ZIP="/tmp/opatch.zip"
PATCHES_DIR="/tmp/oneoffs"
OGG_HOME="/u01/ogg"

##
##  Terminate with an error message
##
function abort() {
    echo "Error - $*"
    exit 1
}

##
##  Run a command as the 'ogg' user
##
function run_as_ogg() {
    local uid gid
    uid="$(id -u ogg)"
    gid="$(id -g ogg)"
    setpriv \
        --reuid  "$uid" \
        --regid  "$gid" \
        --clear-groups \
        "$@"
}

##
##  Returns 0 (true) if at least one non-empty patch ZIP exists in PATCHES_DIR
##
function has_patches() {
    for p in "${PATCHES_DIR}"/*; do
        [ -f "$p" ] && [ -s "$p" ] && return 0 || true
    done
    return 1
}

##
##  Replace the bundled OPatch with the provided ZIP
##
function replace_opatch() {
    echo "Replacing OPatch..."
    rm -rf "${OGG_HOME}/OPatch"
    unzip -q "${OPATCH_ZIP}" -d "${OGG_HOME}"
    chown -R ogg:ogg "${OGG_HOME}/OPatch"
    echo "OPatch replaced successfully"
}

##
##  Apply all one-off patches found in PATCHES_DIR
##
function apply_patches() {
    for p in "${PATCHES_DIR}"/*; do
        [ -f "$p" ] && [ -s "$p" ] && /tmp/apply-oneoff-opatch.sh "$p"
    done
}

##
##  Main
##

if has_patches; then
    [ -s "${OPATCH_ZIP}" ] || abort "OPATCH_ZIP is required when one-off patches are provided"
    replace_opatch
    apply_patches
elif [ -s "${OPATCH_ZIP}" ]; then
    replace_opatch
else
    echo "No patches to apply, using bundled OPatch"
fi

# Cleanup
rm -f  "${OPATCH_ZIP}"
rm -rf "${PATCHES_DIR}" /tmp/apply-oneoff-opatch.sh
