$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$releaseBase = 'https://github.com/seriousCoding/mkscript/releases/latest/download'
$archiveName = 'mkscript-windows-x64.zip'
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ('mkscript-install-' + [guid]::NewGuid())

try {
    New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
    $archive = Join-Path $temporaryDirectory $archiveName
    $checksums = Join-Path $temporaryDirectory 'SHA256SUMS'
    Invoke-WebRequest "$releaseBase/$archiveName" -OutFile $archive
    Invoke-WebRequest "$releaseBase/SHA256SUMS" -OutFile $checksums

    $checksumLine = Get-Content -LiteralPath $checksums | Where-Object { $_ -match "\s\*?$([regex]::Escape($archiveName))$" } | Select-Object -First 1
    if (-not $checksumLine -or $checksumLine -notmatch '^([A-Fa-f0-9]{64})\s') {
        throw "SHA256SUMS does not contain $archiveName."
    }
    $expectedHash = $Matches[1]
    $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) { throw "Checksum mismatch for $archiveName." }

    $package = Join-Path $temporaryDirectory 'package'
    Expand-Archive -LiteralPath $archive -DestinationPath $package
    & (Join-Path $package 'install.ps1')
} finally {
    Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
