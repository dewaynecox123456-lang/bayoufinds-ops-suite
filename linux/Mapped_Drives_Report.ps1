$ErrorActionPreference = "Stop"
$ScriptVersion = "v0.1"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$UserContext = "$env:USERDOMAIN\$env:USERNAME"
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$OutFile = Join-Path $OutputDir ("mapped_drives_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# Collect mapped drives from PSDrive
$mappedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
    $_.DisplayRoot -or ($_.Root -like "\\*")
} | Select-Object Name, Root, DisplayRoot, Description

"══════════════════════════════════════" | Set-Content $OutFile
"MAPPED DRIVES REPORT" | Add-Content $OutFile
"══════════════════════════════════════" | Add-Content $OutFile
"" | Add-Content $OutFile

"══════════════════════════════════════" | Add-Content $OutFile
"AUDIT METADATA" | Add-Content $OutFile
"══════════════════════════════════════" | Add-Content $OutFile
"- Generated: $Timestamp" | Add-Content $OutFile
"- Operator: $Operator" | Add-Content $OutFile
"- Computer: $Computer" | Add-Content $OutFile
"- Domain: $Domain" | Add-Content $OutFile
"- User Context: $UserContext" | Add-Content $OutFile
"- Script Version: $ScriptVersion" | Add-Content $OutFile
"" | Add-Content $OutFile

"══════════════════════════════════════" | Add-Content $OutFile
"MAPPED DRIVES" | Add-Content $OutFile
"══════════════════════════════════════" | Add-Content $OutFile

if ($mappedDrives) {
    foreach ($drive in $mappedDrives) {
        $target = if ($drive.DisplayRoot) { $drive.DisplayRoot } else { $drive.Root }
        "- $($drive.Name): -> $target" | Add-Content $OutFile
    }
} else {
    "- No mapped drives detected" | Add-Content $OutFile
}

"" | Add-Content $OutFile
"══════════════════════════════════════" | Add-Content $OutFile
"INSIGHT" | Add-Content $OutFile
"══════════════════════════════════════" | Add-Content $OutFile

if ($mappedDrives) {
    "- $($mappedDrives.Count) mapped drive(s) detected" | Add-Content $OutFile
    "- Review stale or unauthorized mappings if user role changed" | Add-Content $OutFile
} else {
    "- No mapped drives found in current user context" | Add-Content $OutFile
}

"" | Add-Content $OutFile
"Report complete: $OutFile" | Add-Content $OutFile
Write-Host "Report complete: $OutFile"
