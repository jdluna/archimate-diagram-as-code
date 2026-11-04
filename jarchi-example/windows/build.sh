#!/usr/bin/env bash
# Compile jArchi 1.7.0 inside an Archi 5.3.0 source tree.
# Java and Maven come from the current Git Bash environment (sdk use).
# This script does not download a JDK, Maven, or Archi.
set -euo pipefail

# $0 is /usr/bin/bash under Git Bash, so dirname of it is /usr/bin.
# BASH_SOURCE is the script file that was started.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE="$(cd "$ROOT/.." && pwd)"
# Same folder the macOS build uses: jarchi-example/dist.
# Create it now. The jars are copied in after Maven finishes.
DIST="$EXAMPLE/dist"
mkdir -p "$DIST"

if [[ -f "$ROOT/local.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/local.env"
  set +a
fi

# local.env must not move the output. The folder is the macOS one.
DIST="$EXAMPLE/dist"
mkdir -p "$DIST"

if ! command -v cygpath >/dev/null 2>&1; then
  echo "Run this script from Git Bash. cygpath was not found." >&2
  exit 1
fi

to_unix() {
  cygpath -u "$1"
}

# Maven's own local repository. help:evaluate prints a Windows path, and on
# Git Bash that output is often mixed with log lines, so only a real directory
# is accepted. The fallbacks are the two places a JDK looks for .m2.
maven_local_repo() {
  local raw unix candidate
  raw="$(mvn -B -q help:evaluate -Dexpression=settings.localRepository -DforceStdout 2>/dev/null | tr -d '\r\n' || true)"
  raw="${raw//\\//}"
  if [[ "$raw" == [A-Za-z]:/* || "$raw" == /* ]]; then
    unix="$(cygpath -u "$raw" 2>/dev/null || true)"
    if [[ -n "$unix" && -d "$unix" ]]; then
      printf '%s' "$unix"
      return
    fi
  fi
  for candidate in "${USERPROFILE:-}" "$HOME"; do
    [[ -z "$candidate" ]] && continue
    unix="$(cygpath -u "$candidate/.m2/repository" 2>/dev/null || true)"
    if [[ -n "$unix" && -d "$unix" ]]; then
      printf '%s' "$unix"
      return
    fi
  done
  unix="$(cygpath -u "$HOME/.m2/repository")"
  mkdir -p "$unix"
  printf '%s' "$unix"
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
echo "Dist folder: $DIST"

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
# set). No proxy certificate is required. Fetch each exact version and copy it
# into the local p2 cache Tycho reads. One combined resolve is wrong here:
# javax.servlet.jsp depends on javax.el with a version range, and Maven then
# keeps 3.0.1-b12 instead of the 3.0.0 jar this build needs.
local_repo="$(maven_local_repo)"
local_repo_win="$(cygpath -m "$local_repo")"
echo "Maven local repository: $local_repo"
# org.glassfish:javax.el declares https://maven.java.net as a repository.
# That host is retired and its certificate fails with "validity check failed".
# This settings file sends every lookup to Maven Central. It is used only for
# this prefetch, so the Archi build still uses the normal Maven settings.
central_settings="$(mktemp -d)/settings.xml"
{
  user_settings=""
  for candidate in "$HOME/.m2/settings.xml" "${USERPROFILE:-}/.m2/settings.xml"; do
    [[ -z "$candidate" ]] && continue
    candidate="$(cygpath -u "$candidate" 2>/dev/null || true)"
    if [[ -n "$candidate" && -f "$candidate" ]]; then
      user_settings="$candidate"
      break
    fi
  done
  print_mirror() {
    printf '%s\n' \
      '    <mirror>' \
      '      <id>maven-central-only</id>' \
      '      <url>https://repo.maven.apache.org/maven2</url>' \
      '      <mirrorOf>*</mirrorOf>' \
      '    </mirror>'
  }
  if [[ -z "$user_settings" ]]; then
    printf '%s\n' '<settings>' '  <mirrors>'
    print_mirror
    printf '%s\n' '  </mirrors>' '</settings>'
  elif grep -q '<mirrors[[:space:]]*/>' "$user_settings"; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line//$'\r'/}"
      if [[ "$line" == *"<mirrors"*"/>"* && -z "${mirror_done:-}" ]]; then
        printf '%s\n' '  <mirrors>'
        print_mirror
        printf '%s\n' '  </mirrors>'
        mirror_done=1
      else
        printf '%s\n' "$line"
      fi
    done < "$user_settings"
  elif grep -q '<mirrors>' "$user_settings"; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line//$'\r'/}"
      printf '%s\n' "$line"
      if [[ "$line" == *"<mirrors>"* && -z "${mirror_done:-}" ]]; then
        print_mirror
        mirror_done=1
      fi
    done < "$user_settings"
  else
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line//$'\r'/}"
      if [[ "$line" == *"</settings>"* && -z "${mirror_done:-}" ]]; then
        printf '%s\n' '  <mirrors>'
        print_mirror
        printf '%s\n' '  </mirrors>'
        mirror_done=1
      fi
      printf '%s\n' "$line"
    done < "$user_settings"
  fi
} > "$central_settings"
unset -f print_mirror
unset mirror_done
while IFS='|' read -r bundle_id bundle_version group artifact maven_version; do
  bundle_id="${bundle_id//$'\r'/}"
  bundle_version="${bundle_version//$'\r'/}"
  group="${group//$'\r'/}"
  artifact="${artifact//$'\r'/}"
  maven_version="${maven_version//$'\r'/}"
  [[ -z "$bundle_id" || "$bundle_id" == \#* ]] && continue
  group_path="${group//.//}"
  src="${local_repo}/${group_path}/${artifact}/${maven_version}/${artifact}-${maven_version}.jar"
  dest="${local_repo}/p2/osgi/bundle/${bundle_id}/${bundle_version}/${bundle_id}-${bundle_version}.jar"
  if [[ ! -f "$src" ]]; then
    # Protect only the repository URL. Disabling every path conversion makes
    # java.exe miss Maven's launcher jar.
    MSYS2_ARG_CONV_EXCL="-DremoteRepositories=" mvn -s "$central_settings" -B -Dmaven.repo.local="$local_repo_win" \
      org.apache.maven.plugins:maven-dependency-plugin:3.6.1:get \
      -Dartifact="${group}:${artifact}:${maven_version}:jar" \
      -Dtransitive=false \
      -DremoteRepositories=https://repo.maven.apache.org/maven2
  fi
  if [[ ! -f "$src" ]]; then
    echo "Maven Central did not provide ${group}:${artifact}:${maven_version}." >&2
    echo "Expected file: $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
done < "$ROOT/central-bundles.txt"

(
  cd "$ARCHI_SRC"
  # eclipse.p2.mirrors=false keeps p2 on download.eclipse.org. A mirror that
  # returns 403 is what fails the draw2d compile.
  mvn -B -Dmaven.repo.local="$local_repo_win" -Drevision=5.3.0-SNAPSHOT -Declipse.p2.mirrors=false clean package -DskipTests -P'!tests'
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
