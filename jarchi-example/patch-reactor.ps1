# Add the three jArchi bundles to the Archi reactor and write each bundle pom.
# Called by build-jarchi.bat. No machine-wide install.
param(
    [Parameter(Mandatory = $true)][string]$PomPath,
    [Parameter(Mandatory = $true)][string]$Jarchi,
    [Parameter(Mandatory = $true)][string]$ArchiVersion,
    [Parameter(Mandatory = $true)][string]$JarchiVersion
)

$ErrorActionPreference = "Stop"

$text = [System.IO.File]::ReadAllText($PomPath) -replace "`r`n", "`n" -replace "`r", "`n"
$modules = @(
    "../archi-scripting-plugin/com.archimatetool.script",
    "../archi-scripting-plugin/com.archimatetool.script.commandline",
    "../archi-scripting-plugin/com.archimatetool.script.nashorn"
)
$block = (($modules | ForEach-Object { "        <module>$($_)</module>" }) -join "`n")
$marker = "        <!-- jarchi-example modules -->"
if ($text.IndexOf($marker) -lt 0) {
    $anchor = "        <module>org.opengroup.archimate.xmlexchange.commandline</module>"
    $at = $text.IndexOf($anchor)
    if ($at -lt 0) { throw "Could not find the Archi module list to extend" }
    $text = $text.Remove($at, $anchor.Length).Insert($at, $anchor + "`n" + $marker + "`n" + $block)
}
$ee = "<executionEnvironment>JavaSE-21</executionEnvironment>"
if ($text.IndexOf($ee) -lt 0) {
    $anchor = "                    <target>`n                        <file>`${target.file}</file>`n                    </target>"
    $at = $text.IndexOf($anchor)
    if ($at -lt 0) { throw "Could not find the Archi target-platform configuration" }
    $text = $text.Remove($at, $anchor.Length).Insert($at, $anchor + "`n                    " + $ee)
}
[System.IO.File]::WriteAllText($PomPath, $text)

$pom = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.archimatetool</groupId>
        <artifactId>archi</artifactId>
        <version>`${revision}</version>
        <relativePath>../../archi/pom.xml</relativePath>
    </parent>
    <properties>
        <revision>__ARCHI_VERSION__</revision>
    </properties>
    <artifactId>__ARTIFACT__</artifactId>
    <version>__JARCHI_VERSION__</version>
    <packaging>eclipse-plugin</packaging>
</project>
"@

foreach ($artifact in @(
        "com.archimatetool.script",
        "com.archimatetool.script.commandline",
        "com.archimatetool.script.nashorn")) {
    $path = Join-Path (Join-Path $Jarchi $artifact) "pom.xml"
    $body = $pom.Replace("__ARCHI_VERSION__", $ArchiVersion).Replace("__JARCHI_VERSION__", $JarchiVersion).Replace("__ARTIFACT__", $artifact)
    [System.IO.File]::WriteAllText($path, $body)
    Write-Output "wrote $path"
}
