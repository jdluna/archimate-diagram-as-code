#!/usr/bin/env bash
# Compile jArchi v1.12.0 from source inside the Archi 5.10.0 reactor.
# jArchi is not a standalone program. Its bundles depend on Archi's plug-ins,
# so the Archi sources are the target platform and the reactor parent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/.build"
ARCHI="$BUILD/archi"
JARCHI="$BUILD/archi-scripting-plugin"
DIST="$ROOT/dist"

ARCHI_TAG="release_5.10.0"
JARCHI_TAG="v1.12.0"
ARCHI_VERSION="5.10.0-SNAPSHOT"
JARCHI_VERSION="1.12.0-SNAPSHOT"

java_major=""
if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
  java_major="$("$JAVA_HOME/bin/java" -version 2>&1 | awk -F '\"' '/version/ {split($2, v, "."); print v[1]}')"
fi
if [[ "$java_major" != "21" ]]; then
  JAVA_HOME=""
  for candidate in \
    "$HOME/.sdkman/candidates/java/21.0.7-tem" \
    "$HOME/.sdkman/candidates/java/21.0.8-graal" \
    "$HOME/.sdkman/candidates/java/21.0.2-graalce"
  do
    if [[ -x "$candidate/bin/java" ]]; then
      JAVA_HOME="$candidate"
      break
    fi
  done
fi

if [[ -z "${JAVA_HOME:-}" || ! -x "${JAVA_HOME}/bin/java" ]]; then
  echo "JDK 21 is required. Set JAVA_HOME to a JDK 21 installation." >&2
  exit 1
fi

java_version="$("$JAVA_HOME/bin/java" -version 2>&1 | awk -F '\"' '/version/ {print $2}')"
if [[ "$java_version" != 21* ]]; then
  echo "JAVA_HOME points at Java $java_version. jArchi 1.12 and Archi 5.10 need Java 21." >&2
  exit 1
fi
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

# Tycho 5.0.4, which Archi 5.10 pins, refuses Maven older than 3.9.9.
maven_ok=0
if command -v mvn >/dev/null 2>&1; then
  maven_version="$(mvn -version | awk '/Apache Maven/ {print $3; exit}')"
  maven_minor="$(printf '%s' "$maven_version" | awk -F. '{print $2 * 1000 + $3}')"
  if [[ "${maven_version%%.*}" -eq 3 && "$maven_minor" -ge 9009 ]] || [[ "${maven_version%%.*}" -gt 3 ]]; then
    maven_ok=1
    MVN="$(command -v mvn)"
  fi
fi
if [[ "$maven_ok" -ne 1 ]]; then
  MVN_HOME="$BUILD/apache-maven-3.9.11"
  MVN="$MVN_HOME/bin/mvn"
  if [[ ! -x "$MVN" ]]; then
    mkdir -p "$BUILD"
    echo "Downloading Maven 3.9.11 (Archi 5.10's Tycho build requires 3.9.9 or newer)"
    curl -fL --retry 3 -o "$BUILD/apache-maven-3.9.11-bin.tar.gz" \
      https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.tar.gz
    tar -xzf "$BUILD/apache-maven-3.9.11-bin.tar.gz" -C "$BUILD"
  fi
fi

mkdir -p "$BUILD"
if [[ ! -d "$ARCHI/.git" ]]; then
  git clone --depth 1 --branch "$ARCHI_TAG" https://github.com/archimatetool/archi.git "$ARCHI"
fi
if [[ ! -d "$JARCHI/.git" ]]; then
  git clone --depth 1 --branch "$JARCHI_TAG" https://github.com/archimatetool/archi-scripting-plugin.git "$JARCHI"
fi

git -C "$ARCHI" fetch --depth 1 origin "tag" "$ARCHI_TAG"
git -C "$ARCHI" checkout --detach "$ARCHI_TAG"
git -C "$JARCHI" fetch --depth 1 origin "tag" "$JARCHI_TAG"
git -C "$JARCHI" checkout --detach "$JARCHI_TAG"

python3 - "$ARCHI/pom.xml" "$JARCHI" "$ARCHI_VERSION" "$JARCHI_VERSION" <<'PY'
import pathlib, sys
pom_path, jarchi, archi_version, jarchi_version = sys.argv[1:]
pom = pathlib.Path(pom_path)
text = pom.read_text()
modules = [
    "../archi-scripting-plugin/com.archimatetool.script",
    "../archi-scripting-plugin/com.archimatetool.script.commandline",
    "../archi-scripting-plugin/com.archimatetool.script.nashorn",
]
block = "\n".join(f"        <module>{module}</module>" for module in modules)
marker = "        <!-- jarchi-example modules -->"
if marker not in text:
    anchor = "        <module>org.opengroup.archimate.xmlexchange.commandline</module>"
    if anchor not in text:
        sys.exit("Could not find the Archi module list to extend")
    text = text.replace(anchor, anchor + "\n" + marker + "\n" + block, 1)
if "<executionEnvironment>JavaSE-21</executionEnvironment>" not in text:
    anchor = "                    <target>\n                        <file>${target.file}</file>\n                    </target>"
    if anchor not in text:
        sys.exit("Could not find the Archi target-platform configuration")
    text = text.replace(
        anchor,
        anchor + "\n                    <executionEnvironment>JavaSE-21</executionEnvironment>",
        1,
    )
pom.write_text(text)

pom_xml = """<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.archimatetool</groupId>
        <artifactId>archi</artifactId>
        <version>${revision}</version>
        <relativePath>../../archi/pom.xml</relativePath>
    </parent>
    <properties>
        <revision>__ARCHI_VERSION__</revision>
    </properties>
    <artifactId>__ARTIFACT__</artifactId>
    <version>__JARCHI_VERSION__</version>
    <packaging>eclipse-plugin</packaging>
</project>
"""
for artifact in (
    "com.archimatetool.script",
    "com.archimatetool.script.commandline",
    "com.archimatetool.script.nashorn",
):
    path = pathlib.Path(jarchi) / artifact / "pom.xml"
    path.write_text(
        pom_xml.replace("__ARCHI_VERSION__", archi_version)
        .replace("__JARCHI_VERSION__", jarchi_version)
        .replace("__ARTIFACT__", artifact)
    )
    print(f"wrote {path}")
PY

echo "Compiling with Java $java_version and $("$MVN" -version | head -1)"
cd "$ARCHI"
"$MVN" -B -Drevision="$ARCHI_VERSION" clean package -DskipTests -P'!tests'

mkdir -p "$DIST"
rm -f "$DIST"/*.jar
for artifact in \
  com.archimatetool.script \
  com.archimatetool.script.commandline \
  com.archimatetool.script.nashorn
do
  jar="$(find "$JARCHI/$artifact/target" -maxdepth 1 -type f -name '*.jar' \
    ! -name '*sources*' ! -name '*javadoc*' | head -1)"
  if [[ -z "$jar" ]]; then
    echo "No bundle jar produced for $artifact" >&2
    exit 1
  fi
  cp "$jar" "$DIST/"
  echo "Installed $(basename "$jar")"
done

echo "jArchi bundles are in $DIST"
