$ErrorActionPreference = "Stop"
$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$ReportFile = Join-Path $OutputDir ("local_admin_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

$admins = @()
try {
    $admins = Get-LocalGroupMember -Group "Administrators"
} catch {
    $admins = @()
}

"══════════════════════════════════════" | Set-Content $ReportFile
"LOCAL ADMIN AUDIT REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"Generated: $Timestamp" | Add-Content $ReportFile
"Operator: $Operator" | Add-Content $ReportFile
"Computer: $Computer" | Add-Content $ReportFile
"Domain: $Domain" | Add-Content $ReportFile
"Script Version: $ScriptVersion" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"Local Administrators Found: $($admins.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

if ($admins.Count -gt 0) {
    foreach ($a in $admins) {
        "- $($a.Name) | Type: $($a.ObjectClass) | Source: $($a.PrincipalSource)" | Add-Content $ReportFile
    }
} else {
    "- No local administrator data returned or insufficient permissions." | Add-Content $ReportFile
}

"" | Add-Content $ReportFile
"INSIGHT:" | Add-Content $ReportFile
"- Review local admin membership for unauthorized or stale privileged access." | Add-Content $ReportFile
"" | Add-Content $ReportFile
"──────────────────────────────────────" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile

Write-Host "Report complete: $ReportFile"
