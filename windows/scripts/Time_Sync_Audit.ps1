$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "time_sync_audit_$RunStamp.txt"

"══════════════════════════════════════" | Set-Content $ReportFile
"TIME SYNC AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Local Time: $(Get-Date)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"w32tm /query /status" | Add-Content $ReportFile
"---------------------" | Add-Content $ReportFile
if (Test-BayouFindsCommand -Name "w32tm.exe" -FriendlyName "Windows Time service query") {
    try {
        w32tm /query /status 2>&1 | Add-Content $ReportFile
    }
    catch {
        "Unable to query w32tm: $($_.Exception.Message)" | Add-Content $ReportFile
    }
}
else {
    "Unable to query w32tm: command not available." | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
