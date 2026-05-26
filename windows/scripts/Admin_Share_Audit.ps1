$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "admin_share_audit_$RunStamp.txt"
$shares = @()
$collectionError = $null

if (Test-BayouFindsCommand -Name "Get-SmbShare" -FriendlyName "SMB share inventory") {
    try {
        $shares = @(Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -match 'ADMIN\$|C\$|IPC\$' })
    }
    catch {
        $collectionError = $_.Exception.Message
    }
}
else {
    $collectionError = "Get-SmbShare is unavailable on this host."
}

"══════════════════════════════════════" | Set-Content $ReportFile
"ADMIN SHARE AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Admin Shares Found: $($shares.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($shares.Count -eq 0) {
  "- No default administrative shares returned." | Add-Content $ReportFile
}
foreach ($s in $shares) {
  "- $($s.Name) | Path: $($s.Path) | Description: $($s.Description)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
