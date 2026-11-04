# Archi 5.3.0 on Windows, from Git Bash

These scripts compile [jArchi 1.7.0](https://github.com/archimatetool/archi-scripting-plugin/tree/v1.7.0)
against the [Archi 5.3.0](https://github.com/archimatetool/archi/tree/release_5.3.0)
source tree, then run the JSON script with the Archi 5.3.0 application you
already have. jArchi 1.7.0 declares Java 17 and Archi 5.2.0 or later, which
is the pair that matches Archi 5.3.0.

`build.sh` and `run.sh` use the JDK and Maven already selected in that Git
Bash window. They do not download Java, Maven, Archi, or the plug-in source.

The model script is `../scripts/create-from-json.ajs`. The sample files are
`../model/claims.json` and `../model/harbor-landscape.json`. The generated
files are `out/claims-handling.archimate` and `out/harbor-landscape.archimate`
in this folder.

## 1. Place the Archi 5.3.0 application

You already downloaded Archi 5.3.0. Unzip the portable zip into a folder you
can write to, for example `C:\Users\you\Archi`. The folder must contain
`Archi.exe`.

In Git Bash that path is `/c/Users/you/Archi`. That value is `ARCHI_HOME`.
`run.sh` reads it and does not copy Archi anywhere else.

## 2. Download the Archi 5.3.0 source

The installed application is the program that runs the script. The compiler
reads a second tree, the Archi source at tag `release_5.3.0`.

Put that tree in this folder:

```text
jarchi-example/windows/src/archi-release_5.3.0
```

That path is `ARCHI_SRC`. The folder contains `pom.xml` with
`<revision>5.3.0-SNAPSHOT</revision>`.

If you already unpacked the tag zip, copy the `archi-release_5.3.0` folder
into `windows/src`. The zip is:

https://github.com/archimatetool/archi/archive/refs/tags/release_5.3.0.zip

From this `windows` directory, git clones into the same place:

```bash
mkdir -p src
git clone --branch release_5.3.0 --depth 1 https://github.com/archimatetool/archi.git src/archi-release_5.3.0
```

## 3. Download jArchi 1.7.0

Put the plug-in source next to the Archi source:

```text
jarchi-example/windows/src/archi-scripting-plugin-1.7.0
```

That path is `JARCHI_SRC`. It contains `com.archimatetool.script`,
`com.archimatetool.script.commandline`, and `com.archimatetool.script.nashorn`.
The script manifest says `Bundle-Version: 1.7.0.qualifier`.

If you already unpacked the tag zip, copy the
`archi-scripting-plugin-1.7.0` folder into `windows/src`. The zip is:

https://github.com/archimatetool/archi-scripting-plugin/archive/refs/tags/v1.7.0.zip

From this `windows` directory:

```bash
mkdir -p src
git clone --branch v1.7.0 --depth 1 https://github.com/archimatetool/archi-scripting-plugin.git src/archi-scripting-plugin-1.7.0
```

Both trees sit under `windows/src`, so they are on the same drive. The build
records the path from one tree to the other inside the Archi `pom.xml`.

## 4. Install SDKMAN in Git Bash

SDKMAN is installed under your user profile (`%USERPROFILE%\.sdkman`). The
commands below write only there and in `%USERPROFILE%\.local\bin`.

Every `sdk install` unpacks a zip with `unzip`. Windows 10 and later include
`tar.exe` at `C:\Windows\System32\tar.exe`, and that program opens and creates
zip archives. `install-sdkman.sh` puts `zip` and `unzip` on your user `PATH`.
Both commands call that `tar.exe`. Git Bash also has a program named `tar`;
the script calls Windows `tar.exe` by its full path, so the Git Bash `tar`
is left unused.

SDKMAN itself is saved with the browser, which already uses the proxy.
`install-sdkman.sh` only unpacks those files.

Create `sdkman-download` in this directory. In the browser, save these three
files there. Keep the zip names as they are. Save the third response as
`candidates.txt` (it is one comma-separated line):

```text
https://github.com/sdkman/sdkman-cli/releases/download/5.24.0/sdkman-cli-5.24.0.zip
https://github.com/sdkman/sdkman-cli-native/releases/download/v0.8.0/sdkman-cli-native-0.8.0-x86_64-pc-windows-msvc.zip
https://api.sdkman.io/2/candidates/all
```

A newer pair from the same GitHub release pages also works. The script reads
the version from the folder inside each zip. The native file has to be the
`x86_64-pc-windows-msvc` zip.

From this directory:

```bash
./install-sdkman.sh
source "$HOME/.bashrc"
sdk version
```

`./install-sdkman.sh` unpacks both zips with the `unzip` command from the
step above, copies them to `%USERPROFILE%\.sdkman`, and records
`candidates.txt` as `%USERPROFILE%\.sdkman\var\candidates`. `sdk version`
prints the SDKMAN script version.

The folder `%USERPROFILE%\.sdkman\candidates` is where installed JDKs and
Maven builds live. The list of names `sdk list` knows is the file
`var\candidates` next to it. If the first run happened before
`candidates.txt` was saved, save that file now and run the script again. It
copies the list into place and leaves the rest of the install as it is:

```bash
./install-sdkman.sh
```

The same copy from this directory is:

```bash
mkdir -p "$HOME/.sdkman/var"
cp sdkman-download/candidates.txt "$HOME/.sdkman/var/candidates"
```

`candidates.txt` has to be the one-line response from the candidates address,
with commas between the names.

When `sdk list` or `sdk install` also has to pass the proxy, set the same
proxy the browser uses, then run the install. Answer `Y` when asked to make
the version the default:

```bash
export https_proxy="http://proxy.example:8080"
export http_proxy="$https_proxy"
```

Install a Java 17 build and a Maven:

```bash
sdk list java
sdk install java 17.0.13-tem
sdk list maven
sdk install maven 3.9.6
```

Use the identifiers `sdk list` prints on your machine. `17.0.13-tem` and
`3.9.6` are examples.

Each new Git Bash window reads `.bashrc`, which adds `$HOME/.local/bin` and
then starts SDKMAN. Keep that `bin` directory on `PATH`. `sdk install` still
unpacks its downloads with `unzip`, and that command still calls Windows
`tar.exe`.

## 5. Select Java 17 and Maven with sdk

Open Git Bash. `sdk` has to be available in that window (`sdk version`
prints a version). Pick the JDK 17 and the Maven you already installed:

```bash
sdk list java
sdk use java 17.0.13-tem
sdk current java

sdk list maven
sdk use maven 3.9.6
sdk current maven
```

Use the identifiers `sdk list` prints on your machine. The `17.0.13-tem`
and `3.9.6` lines above are examples. Archi 5.3.0 compiles with Java 17.
`build.sh` stops when `JAVA_HOME` is a different major version.

`sdk use` applies only to this window. Run it again in every new Git Bash
window before `./build.sh`. The script inherits `JAVA_HOME` and `PATH` from
that window.

Check the selection before building:

```bash
echo "$JAVA_HOME"
java -version
mvn -version
```

`java -version` should report 17. `mvn -version` should report the Maven
from `sdk current maven`, and the Java home on its last lines should be the
same JDK.

## 6. Record the three folders

From this `windows` directory:

```bash
cp local.env.example local.env
```

Edit `local.env` so the three exports match the folders from steps 1 to 3.
Leave Java and Maven out of that file. `sdk use` supplies them.

```bash
export ARCHI_HOME="/c/Users/you/Archi"
export ARCHI_SRC="src/archi-release_5.3.0"
export JARCHI_SRC="src/archi-scripting-plugin-1.7.0"
```

`build.sh` and `run.sh` load `local.env` when the file is present. You can
export the same three variables in the window instead of using the file.

## 7. Build

Stay in the same Git Bash window, in this directory:

```bash
cd /c/Users/you/src/archimate-diagram-as-code/jarchi-example/windows
sdk use java 17.0.13-tem
sdk use maven 3.9.6
./build.sh
```

`build.sh` then does the following with those values:

1. Reads `ARCHI_SRC`, `JARCHI_SRC`, `JAVA_HOME`, and `mvn` from the window.
2. Checks that the Archi pom is `5.3.0-SNAPSHOT` and that jArchi is `1.7.0.qualifier`.
3. Writes three `<module>` entries into `ARCHI_SRC/pom.xml` and a `pom.xml`
   into each jArchi bundle. Those files are the local edits the reactor needs.
   The bundle version in each new pom is `1.7.0-SNAPSHOT`, which pairs with
   `1.7.0.qualifier` in the manifest.
4. Runs `mvn -B -Drevision=5.3.0-SNAPSHOT clean package -DskipTests -P'!tests'`
   from `ARCHI_SRC`, using the `mvn` and `JAVA_HOME` from this window.
5. Copies the three jars into `windows/dist`.

The first Maven run downloads the Eclipse 2023-06 dependencies declared by
Archi 5.3.0. Later runs reuse the local Maven cache.

Maven talks to `https://repo.maven.apache.org/maven2`. When the company proxy
presents its own certificate, the JDK reports `PKIX path building failed`
for `org.eclipse.tycho:tycho-build`. `build.sh` sets
`javax.net.ssl.trustStoreType=Windows-ROOT` so that JDK uses the Windows root
certificates, the same ones the browser already trusts. Run `./build.sh`
again after pulling this change.

If the same PKIX error remains, the proxy certificate is not in the Windows
root store. Export that certificate from the browser as `proxy-root.crt`,
then import it into the JDK selected in this window. That JDK lives under
your user profile, so this needs no administrator account:

```bash
keytool -importcert -noprompt \
  -alias corporate-proxy \
  -keystore "$JAVA_HOME/lib/security/cacerts" \
  -storepass changeit \
  -file proxy-root.crt
./build.sh
```

## 8. Generate the model

In that same window:

```bash
./run.sh
./run.sh ../model/claims.json out/claims-handling.archimate
./run.sh ../model/harbor-landscape.json out/harbor-landscape.archimate
```

`run.sh` reads `ARCHI_HOME` and does the following:

1. Copies `dist/com.archimatetool.script*.jar` to `%APPDATA%\Archi\dropins`,
   which is the dropins folder Archi 5.3.0 reads on Windows.
2. Creates `%USERPROFILE%\Documents\Archi\scripts` when that folder is missing.
   jArchi's GraalJS engine expects it.
3. Starts `ARCHI_HOME/Archi.exe` with the window closed:

```text
Archi.exe -clean -application com.archimatetool.commandline.app
  -consoleLog -nosplash --abortOnException
  --script.runScript <create-from-json.ajs>
  --json <claims.json>
  --saveModel <out/claims-handling.archimate>
  --createEmptyModel
```

`--createEmptyModel` stays last because it accepts an optional template path
and would otherwise consume the next argument. Archi still creates the empty
model, runs the script, then saves.

The check at the end prints the element, relationship, and view counts. The
files to open in Archi are `windows/out/claims-handling.archimate` and
`windows/out/harbor-landscape.archimate`.
