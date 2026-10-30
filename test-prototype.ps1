$ErrorActionPreference = 'Stop'
$enginePath = Join-Path $PSScriptRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw 'Missing project-local Godot 4.7.2 engine.' }
$env:APPDATA = Join-Path $PSScriptRoot '.tools/appdata'
$env:CLOUD_DRAGON_TEST_DIR = Join-Path $PSScriptRoot ('.tools/test-data-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
function Invoke-CheckedGodot {
    $lines = @(& $enginePath @args 2>&1)
    $engineExit = $LASTEXITCODE
    $lines | Write-Output
    if ($engineExit -ne 0 -or ($lines -match 'SCRIPT ERROR:|ERROR: Resumed function|ERROR: Error calling deferred method')) { exit 1 }
}
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --script res://tests/check_spatial_actions.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --script res://tests/check_crystal_only.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --script res://tests/check_macos_startup.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot 'docs/superpowers/execution/test-all.log') --script res://tests/run_tests.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/warm-jade-test.log') --script res://tests/test_warm_jade.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/big-motion-test.log') --script res://tests/test_big_motion.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/refined-motion-test.log') --script res://tests/test_motion_v13.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/appearance-settings-test.log') --script res://tests/test_appearance_settings.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$env:CLOUD_DRAGON_DATA_DIR = Join-Path $PSScriptRoot ('.tools/appearance-persistence-' + [guid]::NewGuid().ToString('N'))
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --script res://tests/check_renderer_mode.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --script res://tests/check_font_scale.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --log-file (Join-Path $PSScriptRoot '.tools/appearance-persistence-test.log') --script res://tests/check_appearance_persistence.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
foreach ($check in @('test_ai_core','test_ai_memory','test_ai_settings','test_ai_chat_ui','test_ai_bubble','test_ai_integration','test_ai_chat_integration','test_ai_interaction','check_corgi_details','check_data_tools','check_companion_models','check_v016_ui','check_v016_integration','check_animal_skins','check_companion_ui','check_skin_integration','check_expressive_actions','check_social_interaction','check_expressive_integration')) {
    $env:CLOUD_DRAGON_DATA_DIR = Join-Path $PSScriptRoot ('.tools/v016-' + $check + '-' + [guid]::NewGuid().ToString('N'))
    Invoke-CheckedGodot --headless --path (Join-Path $PSScriptRoot 'desktop-pet') --script ('res://tests/' + $check + '.gd')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
exit $LASTEXITCODE
