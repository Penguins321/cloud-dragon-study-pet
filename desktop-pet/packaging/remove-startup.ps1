$ErrorActionPreference = 'Stop'
$startup = [Environment]::GetFolderPath('Startup','DoNotVerify')
if ([string]::IsNullOrWhiteSpace($startup)) { exit 0 }
$link = Join-Path $startup 'WarmJadeStudyCompanion.lnk'
if (Test-Path -LiteralPath $link) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($link)
    $ours = Join-Path $PSScriptRoot 'WarmJade.exe'
    if ([StringComparer]::OrdinalIgnoreCase.Equals($shortcut.TargetPath, $ours)) {
        Remove-Item -LiteralPath $link -Force
    }
}

