$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\startup_programs_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null

$paths=@(
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)

"══════════════════════════════════════" | Set-Content $ReportFile
"STARTUP PROGRAMS AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
foreach($p in $paths){
  "" | Add-Content $ReportFile
  "PATH: $p" | Add-Content $ReportFile
  try {
    $items=Get-ItemProperty $p
    $items.PSObject.Properties | Where-Object {$_.Name -notmatch '^PS'} | ForEach-Object {
      "- $($_.Name): $($_.Value)" | Add-Content $ReportFile
    }
  } catch {
    "- Not available or access denied" | Add-Content $ReportFile
  }
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
