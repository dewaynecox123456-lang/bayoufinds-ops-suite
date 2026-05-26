$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "scheduled_tasks_audit_$RunStamp.txt"
$tasks = @()
$collectionError = $null

if (Test-BayouFindsCommand -Name "Get-ScheduledTask" -FriendlyName "scheduled task inventory") {
    try {
        $tasks = @(Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.State -ne "Disabled" })
    }
    catch {
        $collectionError = $_.Exception.Message
    }
}
else {
    $collectionError = "Get-ScheduledTask is unavailable on this host."
}

"══════════════════════════════════════" | Set-Content $ReportFile
"SCHEDULED TASKS AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Enabled / Active Tasks Found: $($tasks.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($tasks.Count -eq 0) {
  "- No enabled scheduled tasks returned." | Add-Content $ReportFile
}
foreach ($t in $tasks) {
  "- $($t.TaskPath)$($t.TaskName) | State: $($t.State) | Author: $($t.Author)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
