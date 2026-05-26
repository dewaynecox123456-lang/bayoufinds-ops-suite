[CmdletBinding()]
param(
    [string]$SearchBase = "",
    [string]$OutDir = ".\output"
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Host "ERROR: ActiveDirectory module not found. Run this on a domain-joined machine with RSAT/AD tools installed." -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot -OutDir $OutDir

$groupCsv = Join-Path $OutDir "AD_Role_Audit_Groups_$timestamp.csv"
$memberCsv = Join-Path $OutDir "AD_Role_Audit_GroupMembers_$timestamp.csv"

$groupProps = @(
    "Name",
    "SamAccountName",
    "GroupCategory",
    "GroupScope",
    "Description",
    "ManagedBy",
    "WhenCreated",
    "WhenChanged"
)

$groupParams = @{
    Filter     = '*'
    Properties = $groupProps
}

if ($SearchBase -and $SearchBase.Trim() -ne "") {
    $groupParams.SearchBase = $SearchBase
}

$groups = Get-ADGroup @groupParams | Select-Object `
    Name,
    SamAccountName,
    GroupCategory,
    GroupScope,
    Description,
    ManagedBy,
    WhenCreated,
    WhenChanged

$groups | Sort-Object Name | Export-Csv -Path $groupCsv -NoTypeInformation -Encoding UTF8

$memberRows = foreach ($group in $groups) {
    try {
        $members = Get-ADGroupMember -Identity $group.SamAccountName -Recursive -ErrorAction Stop
        foreach ($member in $members) {
            [PSCustomObject]@{
                GroupName         = $group.Name
                GroupSamAccount   = $group.SamAccountName
                MemberName        = $member.Name
                MemberSamAccount  = $member.SamAccountName
                MemberObjectClass = $member.objectClass
                MemberDN          = $member.DistinguishedName
            }
        }
    } catch {
        [PSCustomObject]@{
            GroupName         = $group.Name
            GroupSamAccount   = $group.SamAccountName
            MemberName        = "<ERROR>"
            MemberSamAccount  = ""
            MemberObjectClass = ""
            MemberDN          = $_.Exception.Message
        }
    }
}

$memberRows | Export-Csv -Path $memberCsv -NoTypeInformation -Encoding UTF8

$totalGroups = $groups.Count
$totalMembershipRows = $memberRows.Count

Write-Host ""
Write-Host "AD Role Audit Report complete." -ForegroundColor Green
Write-Host "Groups CSV:  $groupCsv"
Write-Host "Members CSV: $memberCsv"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Total Groups:            $totalGroups"
Write-Host "Membership Rows Exported $totalMembershipRows"
Write-Host ""
