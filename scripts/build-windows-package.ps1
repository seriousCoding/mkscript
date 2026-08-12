param([string] $DistDirectory = 'dist')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$build = Join-Path $root 'build/windows-package'
$dist = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DistDirectory)
Remove-Item -LiteralPath $build -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $build,$dist -Force | Out-Null
& (Join-Path $PSScriptRoot 'render-windows.ps1') -OutputDirectory $build | Out-Null
Copy-Item (Join-Path $root 'packaging/windows/*') -Destination $build
Copy-Item (Join-Path $root 'README.md'),(Join-Path $root 'INSTALL.md'),(Join-Path $root 'LICENSE') -Destination $build
$archive = Join-Path $dist "mkscript-$version-windows-x64.zip"
Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $build '*') -DestinationPath $archive
Copy-Item -LiteralPath $archive -Destination (Join-Path $dist 'mkscript-windows-x64.zip') -Force
Write-Output $archive
