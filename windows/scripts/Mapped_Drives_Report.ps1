$ErrorActionPreference = "Stop"
$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$UserContext = "$env:USERDOMAIN\$env:USERNAME"
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$ReportFile = Join-Path $OutputDir ("mapped_drives_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

$mappedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
    $_.DisplayRoot -or ($_.Root -like "\\*")
} | Select-Object Name, Root, DisplayRoot, Description

"══════════════════════════════════════" | Set-Content $ReportFile
"MAPPED DRIVES REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"AUDIT METADATA" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- Generated: $Timestamp" | Add-Content $ReportFile
"- Operator: $Operator" | Add-Content $ReportFile
"- Computer: $Computer" | Add-Content $ReportFile
"- Domain: $Domain" | Add-Content $ReportFile
"- User Context: $UserContext" | Add-Content $ReportFile
"- Script Version: $ScriptVersion" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"MAPPED DRIVES" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile

if ($mappedDrives) {
    foreach ($drive in $mappedDrives) {
        $target = if ($drive.DisplayRoot) { $drive.DisplayRoot } else { $drive.Root }
        "- $($drive.Name): -> $target" | Add-Content $ReportFile
    }
} else {
    "- No mapped drives detected" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"INSIGHT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
if ($mappedDrives) {
    "- $($mappedDrives.Count) mapped drive(s) detected." | Add-Content $ReportFile
    "- Review stale or unauthorized mappings if user role changed." | Add-Content $ReportFile
} else {
    "- No mapped drives found in current user context." | Add-Content $ReportFile
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
