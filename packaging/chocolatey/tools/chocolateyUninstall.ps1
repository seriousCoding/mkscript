$ErrorActionPreference = 'Stop'
$wrapperDirectory = Join-Path $env:LOCALAPPDATA 'mkscript\bin'
Uninstall-BinFile -Name 'mkscript'
Uninstall-ChocolateyPath -Path $wrapperDirectory -PathType User
Remove-Item -LiteralPath $wrapperDirectory -Recurse -Force -ErrorAction SilentlyContinue
