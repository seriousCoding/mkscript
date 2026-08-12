[CmdletBinding()]
param(
    [string] $ArchivePath,
    [switch] $SkipChocolateyPack
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if (-not $ArchivePath) { $ArchivePath = Join-Path $root "dist/mkscript-$version-windows-x64.zip" }
$ArchivePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ArchivePath)
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) { throw "Windows archive not found: $ArchivePath" }
$hash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash

function Render([string] $Source, [string] $Destination) {
    $content = (Get-Content -LiteralPath $Source -Raw).Replace('@VERSION@', $version).Replace('@SHA256@', $hash)
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Set-Content -LiteralPath $Destination -Value $content -Encoding UTF8
}

$wingetRoot = Join-Path $root 'dist/winget'
Remove-Item -LiteralPath $wingetRoot -Recurse -Force -ErrorAction SilentlyContinue
$wingetOutput = Join-Path $wingetRoot "seriousCoding/mkscript/$version"
foreach ($name in 'seriousCoding.mkscript.yaml', 'seriousCoding.mkscript.installer.yaml', 'seriousCoding.mkscript.locale.en-US.yaml') {
    Render (Join-Path $root "packaging/winget/$name.in") (Join-Path $wingetOutput $name)
}

$chocolateyOutput = Join-Path $root 'build/chocolatey'
New-Item -ItemType Directory -Path (Join-Path $chocolateyOutput 'tools') -Force | Out-Null
Render (Join-Path $root 'packaging/chocolatey/mkscript.nuspec.in') (Join-Path $chocolateyOutput 'mkscript.nuspec')
Render (Join-Path $root 'packaging/chocolatey/tools/chocolateyInstall.ps1.in') (Join-Path $chocolateyOutput 'tools/chocolateyInstall.ps1')
Copy-Item -LiteralPath (Join-Path $root 'packaging/chocolatey/tools/chocolateyUninstall.ps1') -Destination (Join-Path $chocolateyOutput 'tools/chocolateyUninstall.ps1') -Force

if (-not $SkipChocolateyPack) {
    $choco = Get-Command choco.exe -ErrorAction SilentlyContinue
    if (-not $choco) { throw 'choco.exe is required to build the Chocolatey package; use -SkipChocolateyPack to render only.' }
    & $choco.Source pack (Join-Path $chocolateyOutput 'mkscript.nuspec') --outputdirectory (Join-Path $root 'dist')
    if ($LASTEXITCODE -ne 0) { throw "choco pack failed with exit code $LASTEXITCODE." }
}

Write-Output "WinGet manifest set: $wingetOutput"
Write-Output "Chocolatey source: $chocolateyOutput"
