$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\admin_share_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null
$shares=Get-SmbShare | Where-Object {$_.Name -match 'ADMIN\$|C\$|IPC\$'}

"══════════════════════════════════════" | Set-Content $ReportFile
"ADMIN SHARE AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
foreach($s in $shares){
  "- $($s.Name) | Path: $($s.Path) | Description: $($s.Description)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
