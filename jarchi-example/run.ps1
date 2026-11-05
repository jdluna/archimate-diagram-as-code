# Run the JSON script through Archi's command line.
# Archi is the portable Windows zip, extracted in this folder.
# jArchi jars go in the user dropins folder. No installer and no administrator.
param(
    [string]$Json,
    [string]$Out
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Build = Join-Path $Root ".build"
$Dist = Join-Path $Root "dist"
$Runtime = Join-Path $Build "Archi-Win64"
$Zip = Join-Path $Build "Archi-Win64-5.10.0.zip"
$ZipUrl = "https://github.com/archimatetool/archi.io/releases/download/5.10/Archi-Win64-5.10.0.zip"
$Dropins = Join-Path $env:APPDATA "Archi\dropins"
$ScriptsDir = Join-Path $env:USERPROFILE "Documents\Archi\scripts"
if (-not $Json) { $Json = Join-Path $Root "model\claims.json" }
if (-not $Out) { $Out = Join-Path $Root "out\claims-handling.archimate" }
$Script = Join-Path $Root "scripts\create-from-json.ajs"

$bundles = @(Get-ChildItem $Dist -Filter "com.archimatetool.script*.jar" -ErrorAction SilentlyContinue)
if (-not $bundles) {
    throw "jArchi bundles are not in $Dist. Run build-jarchi.cmd first."
}

New-Item -ItemType Directory -Force -Path $Build | Out-Null
$exe = Get-ChildItem $Runtime -Filter Archi.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    if (-not (Test-Path $Zip)) {
        Write-Host "Downloading Archi 5.10 Windows zip (portable; the Setup exe is not used)"
        & curl.exe -fL --retry 3 -o $Zip $ZipUrl
        if ($LASTEXITCODE -ne 0) { throw "Could not download Archi" }
    }
    if (Test-Path $Runtime) { Remove-Item $Runtime -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Runtime | Out-Null
    Expand-Archive -Path $Zip -DestinationPath $Runtime -Force
    $exe = Get-ChildItem $Runtime -Filter Archi.exe -Recurse | Select-Object -First 1
}
if (-not $exe) { throw "Archi.exe was not found in the Windows zip" }

New-Item -ItemType Directory -Force -Path $Dropins, $ScriptsDir, (Split-Path $Out) | Out-Null
Get-ChildItem $Dropins -Filter "com.archimatetool.script*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force
Copy-Item (Join-Path $Dist "com.archimatetool.script*.jar") $Dropins

$Json = (Resolve-Path $Json).Path
$Out = [System.IO.Path]::GetFullPath($Out)
$Script = (Resolve-Path $Script).Path

# -clean makes Equinox read the dropins jars. -nosplash keeps the window closed.
# --createEmptyModel takes an optional template path and will swallow the next
# token, so it is the last argument. Provider order is still create, script, save.
$argList = @(
    "-clean",
    "-application", "com.archimatetool.commandline.app",
    "-consoleLog",
    "-nosplash",
    "--abortOnException",
    "--script.runScript", $Script,
    "--json", $Json,
    "--saveModel", $Out,
    "--createEmptyModel"
)
$process = Start-Process -FilePath $exe.FullName -ArgumentList $argList -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) { throw "Archi exited with code $($process.ExitCode)" }
if (-not (Test-Path $Out)) { throw "Archi exited without writing $Out" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [System.IO.File]::OpenRead($Out)
try {
    $header = New-Object byte[] 2
    [void]$stream.Read($header, 0, 2)
    $isZip = ($header[0] -eq 0x50 -and $header[1] -eq 0x4B)
}
finally { $stream.Dispose() }

if ($isZip) {
    $zipFile = [System.IO.Compression.ZipFile]::OpenRead($Out)
    try {
        $entry = $zipFile.GetEntry("model.xml")
        if (-not $entry) { throw "The Archi file has no model.xml" }
        $reader = New-Object System.IO.StreamReader($entry.Open())
        try { $xml = $reader.ReadToEnd() }
        finally { $reader.Dispose() }
    }
    finally { $zipFile.Dispose() }
    $kind = "zip"
}
else {
    $xml = [System.IO.File]::ReadAllText($Out)
    $kind = "model xml"
}

$elements = 0
$relationships = 0
$views = 0
foreach ($match in [regex]::Matches($xml, '<element\b[^>]*xsi:type="([^"]+)"')) {
    $type = $match.Groups[1].Value
    if ($type -eq "archimate:ArchimateDiagramModel") { $views += 1 }
    elseif ($type.EndsWith("Relationship")) { $relationships += 1 }
    elseif ($type.StartsWith("archimate:")) { $elements += 1 }
}
$nodes = [regex]::Matches($xml, 'archimateElement="').Count + [regex]::Matches($xml, 'xsi:type="archimate:Note"').Count
$connections = [regex]::Matches($xml, '<sourceConnection\b').Count
Write-Host "$Out ($kind)"
Write-Host "  $elements elements, $relationships relationships, $views views"
Write-Host "  $nodes diagram nodes, $connections diagram connections"
if ($views -lt 1 -or $nodes -lt 1) {
    throw "The Archi file has no generated view"
}
