#!/usr/bin/env bash
# Run the JSON script through Archi's command line, with the compiled jArchi
# bundles in Archi's dropins folder. No Archi window is opened.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/.build"
DIST="$ROOT/dist"
APP="$BUILD/Archi.app"
DMG="$BUILD/Archi-Mac-Silicon-5.10.0.dmg"
DMG_URL="https://github.com/archimatetool/archi.io/releases/download/5.10/Archi-Mac-Silicon-5.10.0.dmg"
DROPINS="${HOME}/Library/Application Support/Archi/dropins"
JSON="${1:-$ROOT/model/claims.json}"
OUT="${2:-$ROOT/out/claims-handling.archimate}"
SCRIPT="$ROOT/scripts/create-from-json.ajs"

# Archi.app keeps its working directory inside the application bundle, so a
# relative path would be read and written next to the Archi binary.
if [[ "$JSON" != /* ]]; then
  JSON="$(cd "$(dirname "$JSON")" && pwd)/$(basename "$JSON")"
fi
mkdir -p "$(dirname "$OUT")"
if [[ "$OUT" != /* ]]; then
  OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
fi

if [[ ! -d "$DIST" || -z "$(find "$DIST" -name 'com.archimatetool.script*.jar' -print -quit)" ]]; then
  echo "jArchi bundles are not in $DIST. Run ./build-jarchi.sh first." >&2
  exit 1
fi

if [[ ! -d "$APP" ]]; then
  echo "Downloading Archi 5.10 for Apple silicon (runtime only; jArchi itself is the source build)"
  mkdir -p "$BUILD"
  curl -fL --retry 3 -o "$DMG" "$DMG_URL"
  mount="$(hdiutil attach -nobrowse "$DMG" | awk -F'\t' '/\/Volumes\// {print $NF; exit}')"
  if [[ -z "$mount" || ! -d "$mount/Archi.app" ]]; then
    echo "Could not find Archi.app in the disk image" >&2
    exit 1
  fi
  rm -rf "$APP"
  cp -R "$mount/Archi.app" "$APP"
  hdiutil detach "$mount" >/dev/null
fi

mkdir -p "$DROPINS" "$(dirname "$OUT")"
rm -f "$DROPINS"/com.archimatetool.script*.jar
cp "$DIST"/com.archimatetool.script*.jar "$DROPINS/"

# GraalJS CommonJS is on by default and refuses to start unless jArchi's
# scripts folder exists. The default is ~/Documents/Archi/scripts.
mkdir -p "${HOME}/Documents/Archi/scripts"

BINARY="$APP/Contents/MacOS/Archi"
if [[ ! -x "$BINARY" ]]; then
  echo "Archi binary not executable at $BINARY" >&2
  exit 1
fi

# -clean makes Equinox read the dropins jars. -nosplash keeps the window closed.
# Provider order is fixed inside ACLI: create the model, run the script, then save.
# --createEmptyModel takes an optional template path and will swallow the next
# token, including another flag, so it has to be the last argument.
"$BINARY" \
  -clean \
  -application com.archimatetool.commandline.app \
  -consoleLog \
  -nosplash \
  --abortOnException \
  --script.runScript "$SCRIPT" \
  --json "$JSON" \
  --saveModel "$OUT" \
  --createEmptyModel

if [[ ! -f "$OUT" ]]; then
  echo "Archi exited without writing $OUT" >&2
  exit 1
fi

python3 - "$OUT" <<'PY'
import sys, zipfile
from xml.etree import ElementTree as ET
path = sys.argv[1]
if zipfile.is_zipfile(path):
    with zipfile.ZipFile(path) as archive:
        xml = archive.read("model.xml")
    kind = "zip"
else:
    xml = open(path, "rb").read()
    kind = "model xml"
root = ET.fromstring(xml)
xsi = "{http://www.w3.org/2001/XMLSchema-instance}type"
elements = relationships = views = 0
for element in root.iter():
    kind_attr = element.get(xsi, "")
    if kind_attr == "archimate:ArchimateDiagramModel":
        views += 1
    elif kind_attr.endswith("Relationship"):
        relationships += 1
    elif kind_attr.startswith("archimate:") and element.tag.endswith("element"):
        elements += 1
nodes = sum(1 for child in root.iter("child") if child.get("archimateElement"))
connections = sum(1 for conn in root.iter("sourceConnection"))
print(f"{path} ({kind})")
print(f"  {elements} elements, {relationships} relationships, {views} views")
print(f"  {nodes} diagram nodes, {connections} diagram connections")
if elements < 1 or views < 1 or nodes < 1:
    sys.exit("The Archi file has no generated view")
PY
