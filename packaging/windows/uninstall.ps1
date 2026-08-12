[CmdletBinding()]
param(
    [string] $InstallDirectory = (Join-Path $env:LOCALAPPDATA 'Programs\mkscript'),
    [string] $WrapperDirectory = (Join-Path $env:LOCALAPPDATA 'mkscript\bin'),
    [switch] $KeepWrappers,
    [switch] $SkipPath
)

$ErrorActionPreference = 'Stop'
$InstallDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InstallDirectory)
$WrapperDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WrapperDirectory)

if (-not $SkipPath) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object {
        $_ -and $_ -ne $InstallDirectory -and $_ -ne $WrapperDirectory
    })
    [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
}

if (-not $KeepWrappers -and (Test-Path -LiteralPath $WrapperDirectory -PathType Container)) {
    Remove-Item -LiteralPath $WrapperDirectory -Recurse -Force
}

# A running script cannot reliably delete its own directory. Use a short-lived
# cmd process after this PowerShell process exits.
$escaped = $InstallDirectory.Replace('"', '""')
Start-Process -FilePath $env:ComSpec -WindowStyle Hidden -ArgumentList '/d', '/c', "ping 127.0.0.1 -n 2 >nul & rmdir /s /q `"$escaped`"" | Out-Null
Write-Host 'mkscript was uninstalled. Open a new terminal to refresh PATH.'
