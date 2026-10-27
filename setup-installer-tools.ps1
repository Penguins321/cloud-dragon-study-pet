param()
$ErrorActionPreference = 'Stop'
$archive = Join-Path $PSScriptRoot '.tools/nsis-3.11.zip'
$compiler = Join-Path $PSScriptRoot '.tools/nsis-3.11/makensis.exe'
if (Test-Path $compiler) { Write-Output $compiler; exit 0 }
New-Item -ItemType Directory -Force (Split-Path $archive) | Out-Null
if (!(Test-Path $archive)) {
    # Mirror bytes are verified against the official SourceForge SHA256 below.
    Invoke-WebRequest 'https://mirror.nju.edu.cn/macports/distfiles/nsis/nsis-3.11.zip' -OutFile $archive
}
$expected = 'c7d27f780ddb6cffb4730138cd1591e841f4b7edb155856901cdf5f214394fa1'
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $expected) { throw 'NSIS ZIP SHA256 mismatch; compiler was not extracted.' }
Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $PSScriptRoot '.tools') -Force
if (!(Test-Path $compiler)) { throw 'NSIS compiler missing after extraction.' }
Write-Output $compiler

