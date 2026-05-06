$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\scheduled_tasks_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null
$tasks=Get-ScheduledTask | Where-Object {$_.State -ne "Disabled"}

"══════════════════════════════════════" | Set-Content $ReportFile
"SCHEDULED TASKS AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Enabled / Active Tasks Found: $($tasks.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
foreach($t in $tasks){
  "- $($t.TaskPath)$($t.TaskName) | State: $($t.State) | Author: $($t.Author)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
