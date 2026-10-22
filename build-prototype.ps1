$ErrorActionPreference = 'Stop'
$enginePath = Join-Path $PSScriptRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
$projectPath = Join-Path $PSScriptRoot 'desktop-pet'
$env:APPDATA = Join-Path $PSScriptRoot '.tools/appdata'
New-Item -ItemType Directory -Path (Join-Path $projectPath 'build'),$env:APPDATA -Force | Out-Null
& $enginePath --headless --path $projectPath --export-debug 'Windows Prototype' --log-file (Join-Path $PSScriptRoot 'docs/superpowers/execution/export.log')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $enginePath --headless --path $projectPath --script res://tests/write_notices.gd
exit $LASTEXITCODE
