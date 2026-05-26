$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "local_user_audit_$RunStamp.txt"
$users = @()
$collectionError = $null

if (Test-BayouFindsCommand -Name "Get-LocalUser" -FriendlyName "local user inventory") {
    try {
        $users = @(Get-LocalUser -ErrorAction Stop)
    }
    catch {
        $collectionError = $_.Exception.Message
    }
}
else {
    $collectionError = "Get-LocalUser is unavailable on this host."
}

"══════════════════════════════════════" | Set-Content $ReportFile
"LOCAL USER AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Local Users Found: $($users.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($users.Count -eq 0) {
  "- No local users returned." | Add-Content $ReportFile
}
foreach ($u in $users) {
  "- $($u.Name) | Enabled: $($u.Enabled) | LastLogon: $($u.LastLogon) | PasswordRequired: $($u.PasswordRequired)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
