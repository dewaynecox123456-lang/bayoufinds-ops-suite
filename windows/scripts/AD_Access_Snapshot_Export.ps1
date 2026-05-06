param(
    [string]$UserName
)

if (-not $UserName) {
    Write-Host ""
    $UserName = Read-Host "Enter SamAccountName (e.g., jsmith)"
}

if (-not $UserName) {
    Write-Host "[ERROR] No username provided. Exiting."
    exit 1
}

$ErrorActionPreference = "Stop"
$ScriptVersion = "v1.1"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN

$SnapshotId = "snapshot_{0}_{1}" -f $UserName, (Get-Date -Format "yyyyMMdd_HHmmss")

$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$ReportFile = Join-Path $OutputDir ("{0}.txt" -f $SnapshotId)
$CsvFile = Join-Path $OutputDir ("{0}.csv" -f $SnapshotId)

Import-Module ActiveDirectory -ErrorAction Stop

$user = Get-ADUser -Identity $UserName -Properties DisplayName, DistinguishedName, SamAccountName
$groups = Get-ADPrincipalGroupMembership -Identity $user | Sort-Object Name

$groups | Select-Object @{
    Name="SnapshotId";Expression={$SnapshotId}
}, @{
    Name="UserName";Expression={$user.SamAccountName}
}, @{
    Name="DisplayName";Expression={$user.DisplayName}
}, @{
    Name="GroupName";Expression={$_.Name}
}, @{
    Name="GroupDN";Expression={$_.DistinguishedName}
}, @{
    Name="ExportedAt";Expression={$Timestamp}
}, @{
    Name="ExportedBy";Expression={$Operator}
}, @{
    Name="Domain";Expression={$Domain}
} | Export-Csv -Path $CsvFile -NoTypeInformation

"══════════════════════════════════════" | Set-Content $ReportFile
"ACCESS SNAPSHOT REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"AUDIT METADATA" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- Snapshot ID: $SnapshotId" | Add-Content $ReportFile
"- Generated: $Timestamp" | Add-Content $ReportFile
"- Operator: $Operator" | Add-Content $ReportFile
"- Computer: $Computer" | Add-Content $ReportFile
"- Domain: $Domain" | Add-Content $ReportFile
"- Script Version: $ScriptVersion" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"USER" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- SamAccountName: $($user.SamAccountName)" | Add-Content $ReportFile
"- DisplayName: $($user.DisplayName)" | Add-Content $ReportFile
"- DistinguishedName: $($user.DistinguishedName)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"GROUP MEMBERSHIP" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
foreach ($g in $groups) {
    "- $($g.Name)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"CSV Snapshot: $CsvFile" | Add-Content $ReportFile
Write-Host "Snapshot complete: $ReportFile"
