# Point the Archi 5.3.0 reactor at a local jArchi 1.7.0 checkout and write each bundle pom.
param(
    [Parameter(Mandatory = $true)][string]$PomPath,
    [Parameter(Mandatory = $true)][string]$Jarchi,
    [Parameter(Mandatory = $true)][string]$RelativePom,
    [Parameter(Mandatory = $true)][string]$ModuleScript,
    [Parameter(Mandatory = $true)][string]$ModuleCommandline,
    [Parameter(Mandatory = $true)][string]$ModuleNashorn
)

$ErrorActionPreference = "Stop"

$text = [System.IO.File]::ReadAllText($PomPath) -replace "`r`n", "`n" -replace "`r", "`n"
$marker = "        <!-- jarchi-example modules -->"
$block = @(
    $marker,
    "        <module>$ModuleScript</module>",
    "        <module>$ModuleCommandline</module>",
    "        <module>$ModuleNashorn</module>"
) -join "`n"

$text = [regex]::Replace($text, "(?s)`n        <!-- jarchi-example modules -->`n        <module>.*?`n        <module>.*?`n        <module>.*?`n", "`n")
$anchor = "        <module>org.opengroup.archimate.xmlexchange.commandline</module>"
$at = $text.IndexOf($anchor)
if ($at -lt 0) { throw "Could not find the Archi 5.3.0 module list in $PomPath" }
$text = $text.Insert($at + $anchor.Length, "`n" + $block)

$ee = "<executionEnvironment>JavaSE-17</executionEnvironment>"
if ($text.IndexOf($ee) -lt 0) {
    $config = "                <configuration>`n                    <environments>"
    $at = $text.IndexOf($config)
    if ($at -lt 0) { throw "Could not find the Archi 5.3.0 target-platform configuration" }
    $replacement = "                <configuration>`n                    $ee`n                    <environments>"
    $text = $text.Remove($at, $config.Length).Insert($at, $replacement)
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($PomPath, $text, $utf8)

$pom = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.archimatetool</groupId>
        <artifactId>archi</artifactId>
        <version>`${revision}</version>
        <relativePath>__RELATIVE_POM__</relativePath>
    </parent>
    <properties>
        <revision>5.3.0-SNAPSHOT</revision>
    </properties>
    <artifactId>__ARTIFACT__</artifactId>
    <version>1.7.0-SNAPSHOT</version>
    <packaging>eclipse-plugin</packaging>
</project>
"@
$pom = $pom.Replace("__RELATIVE_POM__", $RelativePom)

foreach ($artifact in @(
        "com.archimatetool.script",
        "com.archimatetool.script.commandline",
        "com.archimatetool.script.nashorn")) {
    $path = Join-Path (Join-Path $Jarchi $artifact) "pom.xml"
    $body = $pom.Replace("__ARTIFACT__", $artifact)
    [System.IO.File]::WriteAllText($path, $body, $utf8)
    Write-Output "wrote $path"
}
