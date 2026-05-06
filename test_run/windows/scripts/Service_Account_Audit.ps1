$ErrorActionPreference="Stop"
Import-Module ActiveDirectory -ErrorAction Stop
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\service_account_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null

$users=Get-ADUser -Filter * -Properties PasswordNeverExpires,Enabled,Description,LastLogonDate |
Where-Object { $_.SamAccountName -match 'svc|service|sql|app|iis' -or $_.Description -match 'service' }

"══════════════════════════════════════" | Set-Content $ReportFile
"SERVICE ACCOUNT AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Potential Service Accounts Found: $($users.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
foreach($u in $users){
  "- $($u.SamAccountName) | Enabled: $($u.Enabled) | PasswordNeverExpires: $($u.PasswordNeverExpires) | LastLogon: $($u.LastLogonDate) | Desc: $($u.Description)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
