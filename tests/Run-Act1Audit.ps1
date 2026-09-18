param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $GodotPath) { $GodotPath = Join-Path $projectRoot 'Godot_v4.7.2-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot executable not found.' }
$auditRoot = Join-Path ([IO.Path]::GetTempPath()) ('VoidleAudit-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $auditRoot | Out-Null
robocopy $projectRoot $auditRoot /E /XD .git .godot /XF *.exe *.log /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'Could not copy the project for isolated checks.' }
$previousAppData = $env:APPDATA
$previousAudit = $env:VOIDLE_AUDIT
try {
    $env:APPDATA = Join-Path $auditRoot '_user'
    $env:VOIDLE_AUDIT = '1'
    New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
    $importLog = Join-Path $auditRoot 'import.log'
    $importArgs = @('--headless', '--path', ('"' + $auditRoot + '"'), '--editor', '--import', '--quit', '--log-file', ('"' + $importLog + '"'))
    $process = Start-Process -FilePath $GodotPath -ArgumentList $importArgs -PassThru -WindowStyle Hidden
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Import failed. See $importLog" }
    $testLog = Join-Path $auditRoot 'regression.log'
    $testArgs = @('--headless', '--path', ('"' + $auditRoot + '"'), '--scene', 'res://tests/act1_regression.tscn', '--quit-after', '500', '--log-file', ('"' + $testLog + '"'))
    $process = Start-Process -FilePath $GodotPath -ArgumentList $testArgs -PassThru -WindowStyle Hidden
    $process.WaitForExit()
    $result = Get-Content -Raw -LiteralPath $testLog
    Write-Output $result
    Write-Output "Audit files: $auditRoot"
    if ($process.ExitCode -ne 0 -or $result -match 'SCRIPT ERROR|FAIL:' -or $result -notmatch 'ACT1_REGRESSION: \d+ checks, 0 failures') {
        throw 'Regression checks failed or did not finish.'
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:VOIDLE_AUDIT = $previousAudit
}
