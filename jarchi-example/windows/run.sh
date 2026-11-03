#!/usr/bin/env bash
# Run create-from-json.ajs with the jArchi jars built for Archi 5.3.0.
# Uses the Archi 5.3.0 application in ARCHI_HOME. No installer and no administrator rights.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
EXAMPLE="$(cd "$ROOT/.." && pwd)"
JSON="${1:-$EXAMPLE/model/claims.json}"
OUT="${2:-$ROOT/out/claims-handling.archimate}"
SCRIPT="$EXAMPLE/scripts/create-from-json.ajs"

if [[ -f "$ROOT/local.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/local.env"
  set +a
fi

if ! command -v cygpath >/dev/null 2>&1; then
  echo "Run this script from Git Bash. cygpath was not found." >&2
  exit 1
fi

if [[ -z "${ARCHI_HOME:-}" ]]; then
  echo "Set ARCHI_HOME to the Archi 5.3.0 folder that contains Archi.exe." >&2
  exit 1
fi
ARCHI_HOME="$(cygpath -u "$ARCHI_HOME")"
if [[ ! -f "$ARCHI_HOME/Archi.exe" ]]; then
  echo "Archi.exe was not found in ARCHI_HOME=$ARCHI_HOME" >&2
  exit 1
fi

shopt -s nullglob
jars=("$DIST"/com.archimatetool.script*.jar)
shopt -u nullglob
if [[ ${#jars[@]} -eq 0 ]]; then
  echo "jArchi bundles are not in $DIST. Run ./build.sh first." >&2
  exit 1
fi

if [[ -z "${APPDATA:-}" ]]; then
  echo "APPDATA is empty. Start this script from Git Bash." >&2
  exit 1
fi
DROPINS="$(cygpath -u "$APPDATA")/Archi/dropins"
SCRIPTS="$HOME/Documents/Archi/scripts"

mkdir -p "$DROPINS" "$SCRIPTS" "$(dirname "$OUT")"
rm -f "$DROPINS"/com.archimatetool.script*.jar
cp "$DIST"/com.archimatetool.script*.jar "$DROPINS/"
echo "Installed jArchi into $DROPINS"

# GraalJS CommonJS is on by default and needs this folder to exist.
mkdir -p "$SCRIPTS"

ARCHI_EXE="$(cygpath -w "$ARCHI_HOME/Archi.exe")"
SCRIPT_WIN="$(cygpath -w "$SCRIPT")"
JSON_WIN="$(cygpath -w "$JSON")"
OUT_WIN="$(cygpath -w "$OUT")"

MSYS_NO_PATHCONV=1 "$ARCHI_EXE" \
  -clean \
  -application com.archimatetool.commandline.app \
  -consoleLog \
  -nosplash \
  --abortOnException \
  --script.runScript "$SCRIPT_WIN" \
  --json "$JSON_WIN" \
  --saveModel "$OUT_WIN" \
  --createEmptyModel

if [[ ! -f "$OUT" ]]; then
  echo "Archi exited without writing $OUT" >&2
  exit 1
fi

MSYS_NO_PATHCONV=1 powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File "$(cygpath -w "$EXAMPLE/check-model.ps1")" \
  -Path "$(cygpath -w "$OUT")"
