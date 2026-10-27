$ErrorActionPreference = 'Stop'
$enginePath = Join-Path $PSScriptRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw 'Missing project-local Godot 4.7.2 engine.' }
$env:APPDATA = Join-Path $PSScriptRoot '.tools/appdata'
$env:CLOUD_DRAGON_TEST_DIR = Join-Path $PSScriptRoot '.tools/test-data'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
& $enginePath --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot 'docs/superpowers/execution/test-all.log') --script res://tests/run_tests.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $enginePath --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/warm-jade-test.log') --script res://tests/test_warm_jade.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $enginePath --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/big-motion-test.log') --script res://tests/test_big_motion.gd
exit $LASTEXITCODE
