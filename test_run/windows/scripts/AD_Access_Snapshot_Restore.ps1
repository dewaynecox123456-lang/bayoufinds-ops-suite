param(
    [string]$CsvFile,
    [string]$UserName,
    [switch]$WhatIf
)

if (-not $CsvFile) {
    Write-Host ""
    $CsvFile = Read-Host "Enter path to snapshot CSV"
}

if (-not $CsvFile) {
    Write-Host "[ERROR] No CSV file provided. Exiting."
    exit 1
}

if (!(Test-Path $CsvFile)) {
    Write-Host "[ERROR] CSV file not found: $CsvFile"
    exit 1
}

$ErrorActionPreference = "Stop"
$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$LogFile = Join-Path $OutputDir ("access_restore_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Import-Module ActiveDirectory -ErrorAction Stop

$data = Import-Csv -Path $CsvFile

if (-not $data) {
    Write-Host "[ERROR] Snapshot CSV is empty."
    exit 1
}

if (-not $UserName) {
    $UserName = ($data | Select-Object -First 1).UserName
}

if (-not $UserName) {
    Write-Host "[ERROR] Could not determine target username."
    exit 1
}

$user = Get-ADUser -Identity $UserName -Properties SamAccountName, DisplayName
$currentGroups = Get-ADPrincipalGroupMembership -Identity $user | Select-Object -ExpandProperty DistinguishedName
$targetGroups = $data | Select-Object -ExpandProperty GroupDN -Unique

$groupsToAdd = @()
foreach ($groupDn in $targetGroups) {
    if ($groupDn -and ($currentGroups -notcontains $groupDn)) {
        $groupsToAdd += $groupDn
    }
}

"══════════════════════════════════════" | Set-Content $LogFile
"ACCESS SNAPSHOT RESTORE" | Add-Content $LogFile
"══════════════════════════════════════" | Add-Content $LogFile
"" | Add-Content $LogFile

"══════════════════════════════════════" | Add-Content $LogFile
"AUDIT METADATA" | Add-Content $LogFile
"══════════════════════════════════════" | Add-Content $LogFile
"- Generated: $Timestamp" | Add-Content $LogFile
"- Operator: $Operator" | Add-Content $LogFile
"- Computer: $Computer" | Add-Content $LogFile
"- Domain: $Domain" | Add-Content $LogFile
"- Script Version: $ScriptVersion" | Add-Content $LogFile
"- Source CSV: $CsvFile" | Add-Content $LogFile
"" | Add-Content $LogFile

"══════════════════════════════════════" | Add-Content $LogFile
"TARGET USER" | Add-Content $LogFile
"══════════════════════════════════════" | Add-Content $LogFile
"- SamAccountName: $($user.SamAccountName)" | Add-Content $LogFile
"- DisplayName: $($user.DisplayName)" | Add-Content $LogFile
"" | Add-Content $LogFile

"══════════════════════════════════════" | Add-Content $LogFile
"PLANNED RESTORE ACTIONS" | Add-Content $LogFile
"══════════════════════════════════════" | Add-Content $LogFile

if ($groupsToAdd.Count -eq 0) {
    "- No missing groups detected. Nothing to restore." | Add-Content $LogFile
    Write-Host "No missing groups detected. Nothing to restore."
    Write-Host "Log written to: $LogFile"
    exit 0
}

foreach ($groupDn in $groupsToAdd) {
    "- Will add user to: $groupDn" | Add-Content $LogFile
}

"" | Add-Content $LogFile

if ($WhatIf) {
    "Restore mode: WHATIF (no changes applied)" | Add-Content $LogFile
    Write-Host "WHATIF mode: no changes applied."
    Write-Host "Log written to: $LogFile"
    exit 0
}

$confirmation = Read-Host "Proceed with restore? Type YES to continue"
if ($confirmation -ne "YES") {
    "Restore cancelled by operator." | Add-Content $LogFile
    Write-Host "Restore cancelled."
    Write-Host "Log written to: $LogFile"
    exit 0
}

"══════════════════════════════════════" | Add-Content $LogFile
"RESTORE RESULTS" | Add-Content $LogFile
"══════════════════════════════════════" | Add-Content $LogFile

foreach ($groupDn in $groupsToAdd) {
    try {
        Add-ADGroupMember -Identity $groupDn -Members $user.SamAccountName -ErrorAction Stop
        "- Added successfully: $groupDn" | Add-Content $LogFile
    }
    catch {
        "- FAILED to add: $groupDn | Error: $($_.Exception.Message)" | Add-Content $LogFile
    }
}

"" | Add-Content $LogFile
"Restore complete. Log: $LogFile" | Add-Content $LogFile
Write-Host "Restore complete. Log: $LogFile"
