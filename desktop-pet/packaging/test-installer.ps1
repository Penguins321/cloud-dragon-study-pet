param([string]$Version = '0.12')
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot)
$setup = Join-Path $root "desktop-pet/build/dist/WarmJade-v$Version-Setup.exe"
$testDir = Join-Path $root ('.tools/installer-test 中文 ' + [guid]::NewGuid().ToString('N'))
$beforeRegistry = (Get-ItemProperty 'HKCU:\Software\WarmJade' -ErrorAction SilentlyContinue | Out-String)
$shortcuts = @((Join-Path ([Environment]::GetFolderPath('Desktop')) '温玉灵核.lnk'), (Join-Path ([Environment]::GetFolderPath('Programs')) '温玉灵核'), (Join-Path ([Environment]::GetFolderPath('Startup')) 'WarmJadeStudyCompanion.lnk'))
$beforeLinks = @($shortcuts | ForEach-Object { Test-Path -LiteralPath $_ }) -join ','
$p = Start-Process -FilePath $setup -ArgumentList @('/S','/TESTMODE',"/D=$testDir") -WindowStyle Hidden -PassThru -Wait
if ($p.ExitCode -ne 0) { throw "Install failed: $($p.ExitCode)" }
foreach ($name in @('WarmJade.exe','Uninstall.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','.warmjade-test')) {
    if (!(Test-Path -LiteralPath (Join-Path $testDir $name))) { throw "Missing installed $name" }
}
if ((Get-FileHash (Join-Path $testDir 'WarmJade.exe')).Hash -ne (Get-FileHash (Join-Path $root "desktop-pet/build/WarmJadePrototype-v$Version.exe")).Hash) { throw 'Installed payload mismatch' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $root "desktop-pet/build/dist/WarmJade-v$Version-Portable.zip"))
try {
    $entry = $zip.GetEntry('WarmJade.exe')
    if (!$entry) { throw 'Portable ZIP missing executable' }
    $stream = $entry.Open()
    try { $zipHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)) } finally { $stream.Dispose() }
    if ($zipHash -ne (Get-FileHash (Join-Path $testDir 'WarmJade.exe')).Hash) { throw 'Portable ZIP executable differs from installer' }
} finally { $zip.Dispose() }
$oldData = $env:CLOUD_DRAGON_DATA_DIR
try {
    $env:CLOUD_DRAGON_DATA_DIR = Join-Path $testDir 'isolated-progress'
    $log = Join-Path $testDir 'installed-smoke.log'
    $p = Start-Process -FilePath (Join-Path $testDir 'WarmJade.exe') -ArgumentList @('--quit-after','120','--log-file',('"' + $log + '"'),'--','--preview-settings') -WindowStyle Hidden -PassThru -Wait
    if ($p.ExitCode -ne 0) { throw "Installed application failed: $($p.ExitCode)" }
    if (!(Test-Path $log)) { throw 'Installed application smoke log missing' }
    if ((Get-Content -LiteralPath $log -Raw) -match '(?m)(SCRIPT ERROR|ERROR:)') { throw 'Installed application reported an error' }
} finally { $env:CLOUD_DRAGON_DATA_DIR = $oldData }
Write-Output "Payload SHA256: $zipHash"
Set-Content -LiteralPath (Join-Path $testDir 'user-kept.txt') -Value 'Keep unrelated user files'
# _?= disables NSIS self-copy, making -Wait wait for the actual uninstaller.
$p = Start-Process -FilePath (Join-Path $testDir 'Uninstall.exe') -ArgumentList @('/S',"_?=$testDir") -WindowStyle Hidden -PassThru -Wait
if ($p.ExitCode -ne 0) { throw "Uninstall failed: $($p.ExitCode)" }
if (Test-Path (Join-Path $testDir 'WarmJade.exe')) { throw 'Payload was not removed' }
if (!(Test-Path (Join-Path $testDir 'user-kept.txt'))) { throw 'Unrelated user file was removed' }
$afterRegistry = (Get-ItemProperty 'HKCU:\Software\WarmJade' -ErrorAction SilentlyContinue | Out-String)
$afterLinks = @($shortcuts | ForEach-Object { Test-Path -LiteralPath $_ }) -join ','
if ($beforeRegistry -ne $afterRegistry -or $beforeLinks -ne $afterLinks) { throw 'Isolated test changed external integration state' }
Write-Output "PASS: isolated install/uninstall, payload hash, unrelated-file preservation, unchanged HKCU/shortcut presence. Test files: $testDir"



