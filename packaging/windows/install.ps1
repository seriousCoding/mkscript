[CmdletBinding()]
param(
    [string] $InstallDirectory = (Join-Path $env:LOCALAPPDATA 'Programs\mkscript'),
    [string] $WrapperDirectory = (Join-Path $env:LOCALAPPDATA 'mkscript\bin'),
    [switch] $SkipPath
)

$ErrorActionPreference = 'Stop'

if (-not $env:LOCALAPPDATA -and (-not $PSBoundParameters.ContainsKey('InstallDirectory') -or -not $PSBoundParameters.ContainsKey('WrapperDirectory'))) {
    throw 'LOCALAPPDATA is not set. Supply -InstallDirectory and -WrapperDirectory explicitly.'
}

$InstallDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InstallDirectory)
$WrapperDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WrapperDirectory)
New-Item -ItemType Directory -Path $InstallDirectory, $WrapperDirectory -Force | Out-Null

foreach ($name in 'mkscript.exe', 'mkscript.cmd', 'mkscript.ps1', 'uninstall.cmd', 'uninstall.ps1') {
    $source = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "The package is incomplete; missing $name."
    }

    $destination = Join-Path $InstallDirectory $name
    if (-not [string]::Equals($source, $destination, [StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
}

if (-not $SkipPath) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    foreach ($directory in $InstallDirectory, $WrapperDirectory) {
        if ($entries -notcontains $directory) { $entries += $directory }
    }
    [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
}

Write-Host "mkscript installed in: $InstallDirectory"
Write-Host "Global wrappers will be stored in: $WrapperDirectory"
if (-not $SkipPath) { Write-Host 'Open a new terminal, then run: mkscript --version' }
