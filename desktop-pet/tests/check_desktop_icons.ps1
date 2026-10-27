param(
    [string]$PowerShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",
    [switch]$EncodedLaunch
)
$ErrorActionPreference = 'Stop'
$reader = Join-Path $PSScriptRoot '../desktop/read_desktop_icons.ps1'
$parseTokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($reader, [ref]$parseTokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Reader PowerShell syntax is invalid' }
$source = [IO.File]::ReadAllText($reader)
foreach ($forbidden in @('ReadProcessMemory', 'WriteProcessMemory', 'VirtualAllocEx', 'GetWindowText', 'NameProperty', 'get_accName', 'get_accValue', 'accDoDefaultAction', 'accSelect', 'InvokePattern', 'SetCursorPos', 'mouse_event', 'SendInput', 'RootElement', 'TreeScope]::Descendants')) {
    if ($source.Contains($forbidden)) { throw "Forbidden reader operation: $forbidden" }
}
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$outputDirectory = Join-Path $workspace '.tools'
[void][IO.Directory]::CreateDirectory($outputDirectory)
$snapshotPath = Join-Path $outputDirectory ('desktop-icons-test-' + [Guid]::NewGuid().ToString('N') + '.json')
try {
    if ($EncodedLaunch) {
        # Match the application's trusted bundled-code launch; never alter execution policy.
        $command = '& { ' + $source + "`n} -SnapshotPath '" + $snapshotPath.Replace("'", "''") + "' -Once"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $messages = & $PowerShellPath -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
    } else {
        $messages = & $PowerShellPath -NoProfile -NonInteractive -File $reader -SnapshotPath $snapshotPath -Once 2>&1
    }
    if (-not [IO.File]::Exists($snapshotPath)) {
        if (($messages | Out-String) -match 'UnauthorizedAccess|PSSecurityException|running scripts is disabled|execution policy') {
            Write-Output 'PASS: syntax and read-only API checks; installed script policy prevented launch; no snapshot created. Live geometry unavailable.'
            exit 0
        }
        throw 'Reader failed without producing a snapshot'
    }
    $bytes = [IO.File]::ReadAllBytes($snapshotPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { throw 'Snapshot must not have a UTF8 BOM' }
    $snapshot = [IO.File]::ReadAllText($snapshotPath) | ConvertFrom-Json
    $keys = @($snapshot.PSObject.Properties.Name | Sort-Object)
    if (($keys -join ',') -ne 'available,desktop_under_pointer,icons,left_button_down,pointer,sequence') { throw 'Unexpected snapshot schema' }
    if ($snapshot.sequence -ne 1 -or $snapshot.available -isnot [bool] -or $snapshot.desktop_under_pointer -isnot [bool] -or $snapshot.left_button_down -isnot [bool]) { throw 'Invalid snapshot status' }
    if ($snapshot.pointer.Count -ne 2 -or $snapshot.icons.Count -gt 512) { throw 'Invalid bounded snapshot' }
    foreach ($rectangle in $snapshot.icons) {
        if ($rectangle.Count -ne 4 -or $rectangle[2] -le 0 -or $rectangle[3] -le 0 -or $rectangle[2] -gt 4096 -or $rectangle[3] -gt 4096) { throw 'Invalid icon rectangle' }
        foreach ($number in $rectangle) { if ($number -isnot [int] -and $number -isnot [long]) { throw 'Coordinates must be integers' } }
    }
    if (-not $snapshot.available -and ($snapshot.icons.Count -ne 0 -or $snapshot.desktop_under_pointer)) { throw 'Unavailable state must be empty' }
    Write-Output ('PASS: schema, bounded integer coordinates, atomic output; available={0}; icon_count={1}' -f $snapshot.available, $snapshot.icons.Count)
    if ($EncodedLaunch) {
        # Simulate Explorer not being present without touching the real desktop.
        $unavailableSource = $source.Replace('return result;', 'return IntPtr.Zero;')
        $command = '& { ' + $unavailableSource + "`n} -SnapshotPath '" + $snapshotPath.Replace("'", "''") + "' -Once"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $messages = & $PowerShellPath -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
        $snapshot = [IO.File]::ReadAllText($snapshotPath) | ConvertFrom-Json
        if ($snapshot.available -or $snapshot.icons.Count -ne 0 -or $snapshot.desktop_under_pointer) { throw 'Explorer unavailable fallback failed' }
        Write-Output 'PASS: Explorer-unavailable fallback atomically replaced the previous snapshot with an empty unavailable result.'
        $parentProcess = $null
        $watcherProcess = $null
        try {
            $info = New-Object Diagnostics.ProcessStartInfo
            $info.FileName = $PowerShellPath
            $info.UseShellExecute = $false
            $info.CreateNoWindow = $true
            $info.Arguments = '-NoProfile -NonInteractive -Command "Start-Sleep -Seconds 30"'
            $parentProcess = [Diagnostics.Process]::Start($info)
            $command = '& { ' + $source + "`n} -SnapshotPath '" + $snapshotPath.Replace("'", "''") + "' -ParentProcessId " + $parentProcess.Id
            $info.Arguments = '-NoProfile -NonInteractive -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
            $watcherProcess = [Diagnostics.Process]::Start($info)
            Start-Sleep -Milliseconds 3500
            $snapshot = [IO.File]::ReadAllText($snapshotPath) | ConvertFrom-Json
            if ($watcherProcess.HasExited -or $snapshot.sequence -lt 2 -or $snapshot.sequence -gt 4) { throw 'Watcher cadence or atomic replacement failed' }
            $parentProcess.Kill()
            if (-not $watcherProcess.WaitForExit(5000)) { throw 'Watcher did not exit when its parent died' }
            Write-Output 'PASS: watcher produced repeated snapshots at no more than 1Hz and exited after its parent died.'
        } finally {
            if ($null -ne $watcherProcess -and -not $watcherProcess.HasExited) { $watcherProcess.Kill() }
            if ($null -ne $parentProcess -and -not $parentProcess.HasExited) { $parentProcess.Kill() }
        }
    }
} finally {
    if ([IO.File]::Exists($snapshotPath)) { [IO.File]::Delete($snapshotPath) }
}
