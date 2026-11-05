# jArchi from source, then a JSON model

jArchi is a plug-in. It does not start on its own. This folder compiles
[jArchi 1.12.0](https://github.com/archimatetool/archi-scripting-plugin/tree/v1.12.0)
against [Archi 5.10.0](https://github.com/archimatetool/archi/tree/release_5.10.0),
installs the three bundles into Archi's dropins folder, and runs Archi's
command line with the window closed.

The script `scripts/create-from-json.ajs` reads a JSON model and creates
the elements, relationships, and views. `model/claims.json` is the small
landscape and writes `out/claims-handling.archimate`.
`model/harbor-landscape.json` is the full landscape: a context diagram, a
conceptual architecture, and a logical architecture, with every ArchiMate
element type. Each area is a Grouping, and the concepts are nested in that
box. It writes `out/harbor-landscape.archimate`.
`model/parcel-delivery.json` is a parcel company drawn as four views: a
conceptual architecture, a system context, a logical architecture, and a
high-level infrastructure diagram. It writes `out/parcel-delivery.archimate`.
How to write a new JSON file, which concept names Archi accepts, and how the
grid and the line lanes are calculated is in [model/README.md](model/README.md).
Archi opens any of these files with File > Open.

jArchi's repositories have no parent build of their own. The build checks
out Archi `release_5.10.0`, adds the three jArchi bundles to that reactor,
and gives each bundle a `pom.xml` whose version is `1.12.0-SNAPSHOT` so it
matches the `1.12.0.qualifier` in the manifest. The bundles are:

- `com.archimatetool.script` — the JavaScript API and the GraalJS engine
- `com.archimatetool.script.commandline` — the `--script.runScript` ACLI provider
- `com.archimatetool.script.nashorn` — the optional Nashorn engine

The jars are copied to `dist/`. The first run clones both repositories into
`.build/` and downloads the Eclipse 2026-06 target platform. That takes a
while. Later runs reuse the clones and rebuild.

ACLI always runs providers in this order, whatever order the flags are typed:
create or load the model, run the script, then save. `--createEmptyModel`
opens an empty Archi model in memory. It also accepts an optional template
file, and that optional value consumes the next argument, so the flag is
placed last. The script fills the empty model. `--saveModel` writes the
`.archimate` file. `--abortOnException` stops the chain when a provider
throws. A failure inside the script is printed by jArchi and does not abort
the save; the run script then checks that the file contains a view with nodes on it.

The script reads `--json` from `$.process.argv`, which is Eclipse's
application argument list. Element types are Archi's kebab-case names
(`business-actor`, `assignment-relationship`). A view's `viewpoint` is an
Archi viewpoint id (`layered`, `application_usage`, `technology`). A
relationship is drawn on a view when both of its elements are placed on
that view. `"draw": false` keeps the relationship in the model and off the
views. A node with `"parent"` is nested inside that element, which is how
the Harbor groupings hold their members.

`layer` selects an Archi top folder. `Technology` and `Physical` are stored
in Archi's `Technology & Physical` folder. `folder` is a subfolder created under that
folder, and under `Views` for diagrams.

A model with no embedded images is written by Archi as the model XML inside
the `.archimate` file. Archi opens that file with File > Open. A model that
contains images is written as a zip with `model.xml` inside.

GraalJS CommonJS is enabled by default and will not start the script unless
jArchi's scripts folder exists. Each run script creates that folder when it
is missing.

Both platforms need JDK 21. Archi 5.10 and jArchi 1.12 both declare
`JavaSE-21`. Archi 5.10's Tycho build needs Maven 3.9.9 or newer.

## macOS

`JAVA_HOME` must point at JDK 21. If it is unset, or it points at another
release, `build-jarchi.sh` looks for an SDKMAN JDK 21. When the Maven on
`PATH` is older than 3.9.9, the script downloads Maven 3.9.11 into `.build/`.

`run.sh` downloads `Archi-Mac-Silicon-5.10.0` into `.build/Archi.app` and
copies `dist/com.archimatetool.script*.jar` to

`~/Library/Application Support/Archi/dropins`

The scripts folder it creates is `~/Documents/Archi/scripts`.

```bash
cd jarchi-example
./build-jarchi.sh
./run.sh
./run.sh model/claims.json out/claims-handling.archimate
./run.sh model/harbor-landscape.json out/harbor-landscape.archimate
./run.sh model/parcel-delivery.json out/parcel-delivery.archimate
```

`run.sh` launches:

```bash
Archi.app/Contents/MacOS/Archi \
  -clean \
  -application com.archimatetool.commandline.app \
  -consoleLog -nosplash --abortOnException \
  --script.runScript scripts/create-from-json.ajs \
  --json model/claims.json \
  --saveModel out/claims-handling.archimate \
  --createEmptyModel
```

## Windows from Git Bash

The commands are `build-jarchi.bat` and `run-jarchi.bat`. They write only
under this folder, `%APPDATA%\Archi\dropins`, and
`%USERPROFILE%\Documents\Archi\scripts`. The Archi runtime is the portable
zip unpacked into `.build\Archi-Win64`. JDK 21 and Maven 3.9.11 are
downloaded into `.build` when they are not already on `PATH`. Git for
Windows can be a per-user install. The batch files use `curl.exe` and
`tar.exe`, which ship with Windows 10 and later.

From Git Bash, in this folder:

```bash
cmd //c build-jarchi.bat
cmd //c run-jarchi.bat
cmd //c "run-jarchi.bat model/claims.json out/claims-handling.archimate"
cmd //c "run-jarchi.bat model/harbor-landscape.json out/harbor-landscape.archimate"
cmd //c "run-jarchi.bat model/parcel-delivery.json out/parcel-delivery.archimate"
```

`//c` is required so Git Bash passes `/c` through to `cmd`. `run-jarchi.bat`
launches `Archi.exe` with the same ACLI flags as the macOS run, and
`--createEmptyModel` is still the last argument.

For an Archi 5.3.0 application you already have, with Java and Maven chosen
by `sdk` in Git Bash and with the source trees downloaded by hand, use
[windows/README.md](windows/README.md). Those scripts build jArchi 1.7.0.
