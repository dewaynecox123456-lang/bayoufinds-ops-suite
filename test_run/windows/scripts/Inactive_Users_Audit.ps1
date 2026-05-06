param(
    [int]$DaysInactive = 90
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$ReportFile = Join-Path $OutputDir ("inactive_users_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Import-Module ActiveDirectory -ErrorAction Stop

$inactiveUsers = Search-ADAccount -UsersOnly -AccountInactive -TimeSpan "$DaysInactive.00:00:00" |
    Where-Object { $_.Enabled -eq $true } |
    Sort-Object LastLogonDate

"══════════════════════════════════════" | Set-Content $ReportFile
"INACTIVE USERS AUDIT REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"Generated: $Timestamp" | Add-Content $ReportFile
"Operator: $Operator" | Add-Content $ReportFile
"Computer: $Computer" | Add-Content $ReportFile
"Domain: $Domain" | Add-Content $ReportFile
"Script Version: $ScriptVersion" | Add-Content $ReportFile
"Inactive Threshold: $DaysInactive days" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"Inactive Enabled Users Found: $($inactiveUsers.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

foreach ($u in $inactiveUsers) {
    "- $($u.SamAccountName) | LastLogonDate: $($u.LastLogonDate) | DN: $($u.DistinguishedName)" | Add-Content $ReportFile
}

"" | Add-Content $ReportFile
"──────────────────────────────────────" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile

Write-Host "Report complete: $ReportFile"
