param(
    [int]$DaysInactive = 90
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir ("inactive_users_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

if (-not (Import-BayouFindsActiveDirectoryModule)) {
    "INACTIVE USERS AUDIT REPORT" | Set-Content $ReportFile
    "" | Add-Content $ReportFile
    "[ERROR] ActiveDirectory module is unavailable. Run this on a domain-joined system with RSAT/AD tools installed." | Add-Content $ReportFile
    Write-Host "Report complete with errors: $ReportFile" -ForegroundColor Yellow
    exit 1
}

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
