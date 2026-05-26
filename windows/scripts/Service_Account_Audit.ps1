$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "service_account_audit_$RunStamp.txt"
$users = @()
$collectionError = $null

if (Import-BayouFindsActiveDirectoryModule) {
    try {
        $users = @(Get-ADUser -Filter * -Properties PasswordNeverExpires,Enabled,Description,LastLogonDate -ErrorAction Stop |
            Where-Object { $_.SamAccountName -match 'svc|service|sql|app|iis' -or $_.Description -match 'service' })
    }
    catch {
        $collectionError = $_.Exception.Message
    }
}
else {
    $collectionError = "ActiveDirectory module is unavailable."
}

"══════════════════════════════════════" | Set-Content $ReportFile
"SERVICE ACCOUNT AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Potential Service Accounts Found: $($users.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($users.Count -eq 0) {
  "- No potential service accounts matched the current heuristics." | Add-Content $ReportFile
}
foreach ($u in $users) {
  "- $($u.SamAccountName) | Enabled: $($u.Enabled) | PasswordNeverExpires: $($u.PasswordNeverExpires) | LastLogon: $($u.LastLogonDate) | Desc: $($u.Description)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
