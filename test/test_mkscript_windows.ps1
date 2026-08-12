$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& "$root/scripts/render-windows.ps1" | Out-Null
$command = "$root/build/windows/mkscript.ps1"
$launcher = "$root/build/windows/mkscript.exe"
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ("mkscript-test-" + [guid]::NewGuid())
New-Item -ItemType Directory $sandbox | Out-Null
$oldLocalAppData=$env:LOCALAPPDATA; $oldBin=$env:MKSCRIPT_BIN_DIR
try {
    $env:LOCALAPPDATA=Join-Path $sandbox 'local'; $env:MKSCRIPT_BIN_DIR=Join-Path $sandbox 'bin'
    Push-Location $sandbox
    & $command demo
    if (-not (Test-Path demo.cmd)) { throw 'default .cmd creation failed' }
    if ((Get-Content demo.cmd -TotalCount 1) -ne '@echo off') { throw 'invalid cmd template' }
    $launcherVersion = & $launcher --version | Out-String
    if ($LASTEXITCODE -ne 0 -or $launcherVersion -notmatch '^mkscript \d') { throw 'standalone Windows launcher failed' }
    & $launcher 'space name'
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path 'space name.cmd')) { throw 'standalone launcher argument quoting failed' }
    & $command -t terraform main.tf
    if (-not (Select-String -Quiet -LiteralPath main.tf -Pattern 'required_version')) { throw 'terraform template failed' }
    & $command -t ansible site.yml
    if (-not (Select-String -Quiet -LiteralPath site.yml -Pattern 'hosts: all')) { throw 'ansible template failed' }
    & $command -g tool
    if (-not (Test-Path "$env:MKSCRIPT_BIN_DIR/tool.cmd")) { throw 'wrapper creation failed' }
    & $command -c tool
    if ($LASTEXITCODE -ne 0) { throw 'wrapper check failed' }
    & $command -mv tool moved
    if (-not (Test-Path moved.cmd) -or -not (Test-Path "$env:MKSCRIPT_BIN_DIR/moved.cmd") -or (Test-Path "$env:MKSCRIPT_BIN_DIR/tool.cmd")) { throw 'wrapped move failed' }
    $resolved = & $command -f powershell.exe | Out-String
    if ($LASTEXITCODE -ne 0 -or $resolved -notmatch 'command') { throw 'native command lookup failed' }

    $package = Join-Path $sandbox 'package'
    $installed = Join-Path $sandbox 'installed'
    $installedWrappers = Join-Path $sandbox 'installed-bin'
    New-Item -ItemType Directory $package | Out-Null
    Copy-Item "$root/build/windows/*" -Destination $package
    Copy-Item "$root/packaging/windows/*" -Destination $package
    & "$package/install.ps1" -InstallDirectory $installed -WrapperDirectory $installedWrappers -SkipPath
    if (-not (Test-Path "$installed/mkscript.exe") -or -not (Test-Path "$installed/mkscript.cmd") -or -not (Test-Path "$installed/uninstall.cmd")) { throw 'Windows installer failed' }
    Write-Output 'All Windows tests passed.'
} finally {
    Pop-Location -ErrorAction SilentlyContinue
    $env:LOCALAPPDATA=$oldLocalAppData; $env:MKSCRIPT_BIN_DIR=$oldBin
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}
