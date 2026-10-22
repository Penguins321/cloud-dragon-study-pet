$ErrorActionPreference = 'Stop'
$pythonCommand = $null
$pythonArguments = @()
$versionProbe = 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'
foreach ($candidate in @('py', 'python')) {
    if (-not (Get-Command $candidate -ErrorAction SilentlyContinue)) { continue }
    $candidateArguments = @()
    if ($candidate -eq 'py') { $candidateArguments = @('-3') }
    & $candidate @candidateArguments -c $versionProbe *> $null
    if ($LASTEXITCODE -eq 0) {
        $pythonCommand = $candidate
        $pythonArguments = $candidateArguments
        break
    }
}
if ($null -eq $pythonCommand) { throw 'Install Python 3.10+ (launcher or PATH), then run setup-dev.ps1 again.' }
& $pythonCommand @pythonArguments (Join-Path $PSScriptRoot 'scripts/bootstrap-godot.py')
if ($LASTEXITCODE -ne 0) { throw 'Godot setup failed. See the error above; no build was attempted.' }
