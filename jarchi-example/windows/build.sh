#!/usr/bin/env bash
# Compile jArchi 1.7.0 inside an Archi 5.3.0 source tree.
# Java and Maven come from the current Git Bash environment (sdk use).
# This script does not download a JDK, Maven, or Archi.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"

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

to_unix() {
  cygpath -u "$1"
}

require_dir() {
  local name="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo "Set $name in the shell or in windows/local.env. See windows/README.md." >&2
    exit 1
  fi
  if [[ "$value" != /* && "$value" != [A-Za-z]:* ]]; then
    value="$ROOT/$value"
  fi
  local unix
  unix="$(to_unix "$value")"
  if [[ ! -d "$unix" ]]; then
    echo "$name does not exist: $unix" >&2
    exit 1
  fi
  printf '%s' "$unix"
}

ARCHI_SRC="$(require_dir ARCHI_SRC "${ARCHI_SRC:-}")"
JARCHI_SRC="$(require_dir JARCHI_SRC "${JARCHI_SRC:-}")"

if [[ -z "${JAVA_HOME:-}" ]]; then
  echo "JAVA_HOME is empty. In this Git Bash window run: sdk use java <jdk-17-id>" >&2
  exit 1
fi
JAVA_HOME="$(to_unix "$JAVA_HOME")"
export JAVA_HOME
if [[ -x "$JAVA_HOME/bin/java.exe" ]]; then
  JAVA="$JAVA_HOME/bin/java.exe"
elif [[ -x "$JAVA_HOME/bin/java" ]]; then
  JAVA="$JAVA_HOME/bin/java"
else
  echo "No java executable under JAVA_HOME=$JAVA_HOME" >&2
  exit 1
fi

java_version="$("$JAVA" -version 2>&1 | tr -d '\r' | awk -F '"' '/version/ {print $2; exit}')"
java_major="${java_version%%.*}"
if [[ "$java_major" != "17" ]]; then
  echo "JAVA_HOME is Java $java_version. Archi 5.3.0 and jArchi 1.7.0 are built with Java 17." >&2
  echo "In this window run: sdk use java <jdk-17-id>" >&2
  exit 1
fi
export PATH="$JAVA_HOME/bin:$PATH"

if ! command -v mvn >/dev/null 2>&1; then
  echo "mvn was not found. In this Git Bash window run: sdk use maven <maven-id>" >&2
  exit 1
fi

if [[ ! -f "$ARCHI_SRC/pom.xml" ]] || ! grep -q '<revision>5.3.0-SNAPSHOT</revision>' "$ARCHI_SRC/pom.xml"; then
  echo "ARCHI_SRC is not the Archi release_5.3.0 tree: $ARCHI_SRC" >&2
  echo "Check out tag release_5.3.0, or unpack the GitHub zip of that tag." >&2
  exit 1
fi
manifest="$JARCHI_SRC/com.archimatetool.script/META-INF/MANIFEST.MF"
if [[ ! -f "$manifest" ]] || ! grep -q 'Bundle-Version: 1.7.0.qualifier' "$manifest"; then
  echo "JARCHI_SRC is not jArchi v1.7.0: $JARCHI_SRC" >&2
  echo "Check out tag v1.7.0. That release runs on Archi 5.3.0." >&2
  exit 1
fi

for artifact in \
  com.archimatetool.script \
  com.archimatetool.script.commandline \
  com.archimatetool.script.nashorn
do
  if [[ ! -f "$JARCHI_SRC/$artifact/META-INF/MANIFEST.MF" ]]; then
    echo "Missing bundle $artifact under $JARCHI_SRC" >&2
    exit 1
  fi
done

rel_pom="$(realpath --relative-to="$JARCHI_SRC/com.archimatetool.script" "$ARCHI_SRC/pom.xml")"
mod_script="$(realpath --relative-to="$ARCHI_SRC" "$JARCHI_SRC/com.archimatetool.script")"
mod_commandline="$(realpath --relative-to="$ARCHI_SRC" "$JARCHI_SRC/com.archimatetool.script.commandline")"
mod_nashorn="$(realpath --relative-to="$ARCHI_SRC" "$JARCHI_SRC/com.archimatetool.script.nashorn")"

echo "Java $java_version from $JAVA_HOME"
mvn -version
echo "Archi source: $ARCHI_SRC"
echo "jArchi source: $JARCHI_SRC"

MSYS_NO_PATHCONV=1 powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File "$(cygpath -w "$ROOT/patch-reactor.ps1")" \
  -PomPath "$(cygpath -w "$ARCHI_SRC/pom.xml")" \
  -Jarchi "$(cygpath -w "$JARCHI_SRC")" \
  -RelativePom "$rel_pom" \
  -ModuleScript "$mod_script" \
  -ModuleCommandline "$mod_commandline" \
  -ModuleNashorn "$mod_nashorn"

# SDKMAN's JDK trusts the public roots shipped in cacerts. A proxy that
# presents its own certificate is trusted by Windows and by the browser, and
# fails in Maven with "PKIX path building failed". Windows-ROOT is that
# Windows root store.
if [[ "${MAVEN_OPTS:-}" != *javax.net.ssl.trustStoreType* ]]; then
  export MAVEN_OPTS="${MAVEN_OPTS:-} -Djavax.net.ssl.trustStoreType=Windows-ROOT"
fi

# download.eclipse.org answers 403 for the OSGi bundles that are also published
# on Maven Central (org.osgi.service.metatype.annotations and the rest of that
# set). No proxy certificate is required. Resolve them from Maven Central and
# copy each jar into the local p2 cache Tycho reads.
central_pom="$(mktemp -d)/pom.xml"
{
  echo '<project>'
  echo '  <modelVersion>4.0.0</modelVersion>'
  echo '  <groupId>local</groupId>'
  echo '  <artifactId>central-bundles</artifactId>'
  echo '  <version>1</version>'
  echo '  <dependencies>'
  while IFS='|' read -r bundle_id bundle_version group artifact maven_version; do
    [[ -z "$bundle_id" || "$bundle_id" == \#* ]] && continue
    echo "    <dependency><groupId>${group}</groupId><artifactId>${artifact}</artifactId><version>${maven_version}</version></dependency>"
  done < "$ROOT/central-bundles.txt"
  echo '  </dependencies>'
  echo '</project>'
} > "$central_pom"
mvn -f "$central_pom" -B dependency:resolve
while IFS='|' read -r bundle_id bundle_version group artifact maven_version; do
  [[ -z "$bundle_id" || "$bundle_id" == \#* ]] && continue
  group_path="${group//.//}"
  src="${HOME}/.m2/repository/${group_path}/${artifact}/${maven_version}/${artifact}-${maven_version}.jar"
  dest="${HOME}/.m2/repository/p2/osgi/bundle/${bundle_id}/${bundle_version}/${bundle_id}-${bundle_version}.jar"
  if [[ ! -f "$src" ]]; then
    echo "Maven Central did not provide ${group}:${artifact}:${maven_version}." >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
done < "$ROOT/central-bundles.txt"

(
  cd "$ARCHI_SRC"
  # eclipse.p2.mirrors=false keeps p2 on download.eclipse.org. A mirror that
  # returns 403 is what fails the draw2d compile.
  mvn -B -Drevision=5.3.0-SNAPSHOT -Declipse.p2.mirrors=false clean package -DskipTests -P'!tests'
)

mkdir -p "$DIST"
rm -f "$DIST"/*.jar
for artifact in \
  com.archimatetool.script \
  com.archimatetool.script.commandline \
  com.archimatetool.script.nashorn
do
  jar="$(find "$JARCHI_SRC/$artifact/target" -maxdepth 1 -type f -name '*.jar' \
    ! -name '*sources*' ! -name '*javadoc*' -print -quit)"
  if [[ -z "$jar" ]]; then
    echo "No bundle jar produced for $artifact" >&2
    exit 1
  fi
  cp "$jar" "$DIST/"
  echo "Installed $(basename "$jar")"
done

echo "jArchi bundles are in $DIST"
