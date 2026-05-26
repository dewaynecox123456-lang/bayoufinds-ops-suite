$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir ("patch_dump_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# Primary patch sources
$hotfixes = @()
try {
    $hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending
} catch {
    $hotfixes = @()
}

$qfe = @()
try {
    $qfe = Get-CimInstance Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending
} catch {
    $qfe = @()
}

# Legacy WMIC output
$wmicOutput = @()
try {
    $wmicOutput = cmd /c "wmic qfe list full" 2>$null
} catch {
    $wmicOutput = @("WMIC QFE output unavailable.")
}

"══════════════════════════════════════" | Set-Content $ReportFile
"PATCH VALIDATION REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"AUDIT METADATA" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- Generated: $Timestamp" | Add-Content $ReportFile
"- Operator: $Operator" | Add-Content $ReportFile
"- Computer: $Computer" | Add-Content $ReportFile
"- Domain: $Domain" | Add-Content $ReportFile
"- Script Version: $ScriptVersion" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"PATCH SUMMARY" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- Get-HotFix Count: $($hotfixes.Count)" | Add-Content $ReportFile
"- Win32_QuickFixEngineering Count: $($qfe.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"INSTALLED PATCHES (Get-HotFix)" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
if ($hotfixes.Count -gt 0) {
    foreach ($hf in $hotfixes) {
        "- $($hf.HotFixID) | InstalledOn: $($hf.InstalledOn) | Description: $($hf.Description)" | Add-Content $ReportFile
    }
} else {
    "- No Get-HotFix data returned" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"INSTALLED PATCHES (QFE/WMI)" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
if ($qfe.Count -gt 0) {
    foreach ($item in $qfe) {
        "- $($item.HotFixID) | InstalledOn: $($item.InstalledOn) | Description: $($item.Description)" | Add-Content $ReportFile
    }
} else {
    "- No Win32_QuickFixEngineering data returned" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"LEGACY WMIC QFE OUTPUT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
$wmicOutput | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"INSIGHT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
if ($hotfixes.Count -gt 0 -or $qfe.Count -gt 0) {
    "- Patch evidence collected successfully." | Add-Content $ReportFile
    "- Use this report for validation, audit review, and spot-checking patch presence." | Add-Content $ReportFile
} else {
    "- Patch evidence collection returned no records. Review permissions and WMI/HotFix availability." | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"SUPPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- Support: support@bayoufinds.com" | Add-Content $ReportFile
"- Website: https://bayoufinds.com" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"Report complete: $ReportFile" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
