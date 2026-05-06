$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\time_sync_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null

"══════════════════════════════════════" | Set-Content $ReportFile
"TIME SYNC AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Local Time: $(Get-Date)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"w32tm /query /status" | Add-Content $ReportFile
"---------------------" | Add-Content $ReportFile
try { w32tm /query /status | Add-Content $ReportFile } catch { "Unable to query w32tm." | Add-Content $ReportFile }
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
