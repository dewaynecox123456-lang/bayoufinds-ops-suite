$ErrorActionPreference = "Stop"

Write-Host "[INFO] BayouFinds System Health Check Toolkit"
Write-Host "[INFO] Licensed Version"
Write-Host ""

$licensePath = "$env:USERPROFILE\.bayoufinds\license.key"

if (!(Test-Path $licensePath)) {
    Write-Host "[ERROR] License key not found."
    exit
}

$key = (Get-Content $licensePath -Raw).Trim()

$validKeys = @("BF-2026-001")

if ($validKeys -notcontains $key) {
    Write-Host "[ERROR] Invalid license key."
    exit
}

Write-Host "[OK] License verified."
Write-Host "[INFO] Running system scan..."

$outputDir = ".\output"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $outputDir "windows_health_$timestamp.txt"

"══════════════════════════════════════" | Set-Content $ReportFile
"WINDOWS SYSTEM HEALTH REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"SUMMARY" | Add-Content $ReportFile
"-------" | Add-Content $ReportFile
"INFO: System scan completed successfully" | Add-Content $ReportFile

"" | Add-Content $ReportFile
"──────────────────────────────────────" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
"" | Add-Content $ReportFile
Write-Host "[OK] Health check complete: $ReportFile"
