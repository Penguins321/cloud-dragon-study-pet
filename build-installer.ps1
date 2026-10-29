param([string]$Version = '0.16')
$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+(\.\d+)?$') { throw 'Version must be numeric.' }
$parsedVersion = [version]$Version
$versionQuad = '{0}.{1}.{2}.0' -f $parsedVersion.Major,$parsedVersion.Minor,[Math]::Max(0,$parsedVersion.Build)
$compiler = Join-Path $PSScriptRoot '.tools/nsis-3.11/makensis.exe'
if (!(Test-Path $compiler)) { throw 'Run ./setup-installer-tools.ps1 first.' }
$build = Join-Path $PSScriptRoot 'desktop-pet/build'
$payload = Join-Path $build "WarmJadePrototype-v$Version.exe"
foreach ($file in @($payload, (Join-Path $build 'GODOT-LICENSE.txt'), (Join-Path $build 'GODOT-THIRD-PARTY.json'))) {
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing input: $file" }
}
$dist = Join-Path $build 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$setup = Join-Path $dist "WarmJade-v$Version-Setup.exe"
$stage = Join-Path $dist ("portable-stage-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -LiteralPath $payload -Destination (Join-Path $stage 'WarmJade.exe')
Copy-Item -LiteralPath (Join-Path $build 'GODOT-LICENSE.txt'), (Join-Path $build 'GODOT-THIRD-PARTY.json') -Destination $stage
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'desktop-pet/packaging/使用说明.txt') -Destination $stage
$payload = Join-Path $stage 'WarmJade.exe'
& $compiler /INPUTCHARSET UTF8 /V3 "/DROOT=$PSScriptRoot" "/DPAYLOAD=$payload" "/DOUTPUT=$setup" "/DVERSION=$Version" "/DVERSION_QUAD=$versionQuad" (Join-Path $PSScriptRoot 'desktop-pet/packaging/warm-jade.nsi')
if ($LASTEXITCODE -ne 0) { throw "NSIS failed: $LASTEXITCODE" }
$zip = Join-Path $dist "WarmJade-v$Version-Portable.zip"
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
# Remove only the four known files; no recursive deletion of computed paths.
foreach ($name in @('WarmJade.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','使用说明.txt')) { Remove-Item -LiteralPath (Join-Path $stage $name) -Force }
Remove-Item -LiteralPath $stage
Get-FileHash -LiteralPath $setup,$zip -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $([IO.Path]::GetFileName($_.Path))" } | Set-Content (Join-Path $dist 'SHA256SUMS.txt') -Encoding ascii
Get-Item -LiteralPath $setup,$zip



