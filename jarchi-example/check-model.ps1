# Count elements, relationships, and view nodes in an Archi model file.
# The file is model XML when it has no images, and a zip with model.xml when it does.
param(
    [Parameter(Mandatory = $true)][string]$Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$kind = "model xml"
$xmlText = $null
$zip = $null
try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    $entry = $zip.GetEntry("model.xml")
    if ($null -ne $entry) {
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $xmlText = $reader.ReadToEnd()
        $reader.Close()
        $kind = "zip"
    }
} catch {
    $xmlText = $null
} finally {
    if ($null -ne $zip) { $zip.Dispose() }
}
if ($null -eq $xmlText) {
    $xmlText = [System.IO.File]::ReadAllText($Path)
}

$doc = New-Object System.Xml.XmlDocument
$doc.LoadXml($xmlText)
$xsi = "http://www.w3.org/2001/XMLSchema-instance"
$elements = 0
$relationships = 0
$views = 0
$nodes = 0
$connections = 0
foreach ($node in $doc.SelectNodes("//*")) {
    $typeName = $node.GetAttribute("type", $xsi)
    if ($typeName -eq "archimate:ArchimateDiagramModel") {
        $views++
    } elseif ($typeName.EndsWith("Relationship")) {
        $relationships++
    } elseif ($typeName.StartsWith("archimate:") -and $node.LocalName -eq "element") {
        $elements++
    }
    if ($node.LocalName -eq "child" -and $node.GetAttribute("archimateElement")) { $nodes++ }
    if ($node.LocalName -eq "sourceConnection") { $connections++ }
}

Write-Output "$Path ($kind)"
Write-Output "  $elements elements, $relationships relationships, $views views"
Write-Output "  $nodes diagram nodes, $connections diagram connections"
if ($elements -lt 1 -or $views -lt 1 -or $connections -lt 1) {
    Write-Error "The Archi file has no generated view"
    exit 1
}
