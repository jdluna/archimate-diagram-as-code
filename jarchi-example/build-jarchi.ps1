# Compile jArchi v1.12.0 from source inside the Archi 5.10.0 reactor.
# Everything this script downloads stays in this folder or in the user profile.
# It does not write to Program Files and does not ask for an administrator.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Build = Join-Path $Root ".build"
$Archi = Join-Path $Build "archi"
$Jarchi = Join-Path $Build "archi-scripting-plugin"
$Dist = Join-Path $Root "dist"

$ArchiTag = "release_5.10.0"
$JarchiTag = "v1.12.0"
$ArchiVersion = "5.10.0-SNAPSHOT"
$JarchiVersion = "1.12.0-SNAPSHOT"

function Get-JavaMajor([string]$JavaExe) {
    $output = & $JavaExe -version 2>&1 | Out-String
    if ($output -match 'version "1\.(\d+)') { return $Matches[1] }
    if ($output -match 'version "(\d+)') { return $Matches[1] }
    return ""
}

function Find-JavaHome {
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += $env:JAVA_HOME }
    $candidates += @(
        (Join-Path $env:USERPROFILE "scoop\apps\temurin21-jdk\current"),
        (Join-Path $env:LOCALAPPDATA "Programs\Eclipse Adoptium")
    )
    Get-ChildItem -Path $Build -Directory -Filter "jdk-*" -ErrorAction SilentlyContinue | ForEach-Object {
        $candidates += $_.FullName
    }
    Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA "Programs\Eclipse Adoptium") -Directory -Filter "jdk-21*" -ErrorAction SilentlyContinue | ForEach-Object {
        $candidates += $_.FullName
    }
    foreach ($home in $candidates) {
        $java = Join-Path $home "bin\java.exe"
        if ((Test-Path $java) -and (Get-JavaMajor $java) -eq "21") {
            return $home
        }
    }
    return $null
}

function Save-Download([string]$Url, [string]$Destination) {
    Write-Host "Downloading $Url"
    & curl.exe -fL --retry 3 -o $Destination $Url
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $Url" }
}

function Write-Utf8([string]$Path, [string]$Text) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required on PATH. Install Git for the current user, then open a new terminal."
}

New-Item -ItemType Directory -Force -Path $Build | Out-Null

$javaHome = Find-JavaHome
if (-not $javaHome) {
    $zip = Join-Path $Build "temurin-21-windows-x64.zip"
    if (-not (Test-Path $zip)) {
        Save-Download "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk" $zip
    }
    Expand-Archive -Path $zip -DestinationPath $Build -Force
    $javaHome = Find-JavaHome
}
if (-not $javaHome) { throw "JDK 21 was not found after the Temurin download." }
$env:JAVA_HOME = $javaHome
$env:Path = "$(Join-Path $javaHome 'bin');$env:Path"
$javaVersion = (& (Join-Path $javaHome "bin\java.exe") -version 2>&1 | Out-String)
if ($javaVersion -match 'version "([^"]+)"') { $javaVersion = $Matches[1] }

$mvn = $null
if (Get-Command mvn -ErrorAction SilentlyContinue) {
    $mavenVersion = (& mvn -version | Select-Object -First 1 | Out-String)
    if ($mavenVersion -match 'Apache Maven (\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2] * 1000 + [int]$Matches[3]
        if (($major -eq 3 -and $minor -ge 9009) -or $major -gt 3) {
            $mvn = (Get-Command mvn).Source
        }
    }
}
if (-not $mvn) {
    $mvnHome = Join-Path $Build "apache-maven-3.9.11"
    $mvn = Join-Path $mvnHome "bin\mvn.cmd"
    if (-not (Test-Path $mvn)) {
        $zip = Join-Path $Build "apache-maven-3.9.11-bin.zip"
        Save-Download "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.zip" $zip
        Expand-Archive -Path $zip -DestinationPath $Build -Force
    }
}

if (-not (Test-Path (Join-Path $Archi ".git"))) {
    git clone --depth 1 --branch $ArchiTag https://github.com/archimatetool/archi.git $Archi
    if ($LASTEXITCODE -ne 0) { throw "Could not clone Archi" }
}
if (-not (Test-Path (Join-Path $Jarchi ".git"))) {
    git clone --depth 1 --branch $JarchiTag https://github.com/archimatetool/archi-scripting-plugin.git $Jarchi
    if ($LASTEXITCODE -ne 0) { throw "Could not clone jArchi" }
}

git -C $Archi fetch --depth 1 origin tag $ArchiTag
git -C $Archi checkout --force --detach $ArchiTag
git -C $Jarchi fetch --depth 1 origin tag $JarchiTag
git -C $Jarchi checkout --force --detach $JarchiTag
if ($LASTEXITCODE -ne 0) { throw "Could not check out the pinned sources" }

$pomPath = Join-Path $Archi "pom.xml"
$pom = [System.IO.File]::ReadAllText($pomPath)
$modules = @(
    "../archi-scripting-plugin/com.archimatetool.script",
    "../archi-scripting-plugin/com.archimatetool.script.commandline",
    "../archi-scripting-plugin/com.archimatetool.script.nashorn"
)
$block = ($modules | ForEach-Object { "        <module>$_</module>" }) -join "`n"
$marker = "        <!-- jarchi-example modules -->"
if ($pom.IndexOf($marker) -lt 0) {
    $anchor = "        <module>org.opengroup.archimate.xmlexchange.commandline</module>"
    if ($pom.IndexOf($anchor) -lt 0) { throw "Could not find the Archi module list to extend" }
    $pom = $pom.Replace($anchor, $anchor + "`n" + $marker + "`n" + $block)
}
$ee = "<executionEnvironment>JavaSE-21</executionEnvironment>"
if ($pom.IndexOf($ee) -lt 0) {
    $anchor = "                    <target>`n                        <file>`${target.file}</file>`n                    </target>"
    if ($pom.IndexOf($anchor) -lt 0) { throw "Could not find the Archi target-platform configuration" }
    $pom = $pom.Replace($anchor, $anchor + "`n                    $ee")
}
Write-Utf8 $pomPath $pom

$pomXml = @'
<?xml version="1.0" encoding="UTF-8"?>
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
'@
foreach ($artifact in $modules) {
    $name = Split-Path $artifact -Leaf
    $path = Join-Path $Jarchi "$name\pom.xml"
    $text = $pomXml.Replace("__ARCHI_VERSION__", $ArchiVersion).Replace("__JARCHI_VERSION__", $JarchiVersion).Replace("__ARTIFACT__", $name)
    Write-Utf8 $path $text
    Write-Host "wrote $path"
}

$mvnLine = (& $mvn -version | Select-Object -First 1)
Write-Host "Compiling with Java $javaVersion and $mvnLine"
Push-Location $Archi
try {
    & $mvn -B "-Drevision=$ArchiVersion" clean package -DskipTests "-P!tests"
    if ($LASTEXITCODE -ne 0) { throw "Maven build failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Get-ChildItem $Dist -Filter *.jar -ErrorAction SilentlyContinue | Remove-Item -Force
foreach ($artifact in $modules) {
    $name = Split-Path $artifact -Leaf
    $jar = Get-ChildItem (Join-Path $Jarchi "$name\target") -Filter *.jar -File |
        Where-Object { $_.Name -notmatch 'sources|javadoc' } |
        Select-Object -First 1
    if (-not $jar) { throw "No bundle jar produced for $name" }
    Copy-Item $jar.FullName (Join-Path $Dist $jar.Name)
    Write-Host "Installed $($jar.Name)"
}

Write-Host "jArchi bundles are in $Dist"
