$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\local_user_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null
$users=Get-LocalUser

"══════════════════════════════════════" | Set-Content $ReportFile
"LOCAL USER AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Local Users Found: $($users.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
foreach($u in $users){
  "- $($u.Name) | Enabled: $($u.Enabled) | LastLogon: $($u.LastLogon) | PasswordRequired: $($u.PasswordRequired)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
