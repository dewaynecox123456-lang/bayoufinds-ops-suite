[CmdletBinding()]
param(
    [string]$OutDir = ".\output",
    [switch]$MockMode
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function New-PolicyRow {
    param(
        [string]$PolicyType,
        [string]$PolicyName,
        [string]$MinPasswordLength,
        [string]$PasswordHistoryCount,
        [string]$ComplexityEnabled,
        [string]$ReversibleEncryptionEnabled,
        [string]$LockoutThreshold,
        [string]$LockoutDurationMinutes,
        [string]$LockoutObservationWindowMinutes,
        [string]$MinPasswordAgeDays,
        [string]$MaxPasswordAgeDays,
        [string]$Precedence,
        [string]$AppliesTo,
        [string]$Source
    )

    [PSCustomObject]@{
        PolicyType                      = $PolicyType
        PolicyName                      = $PolicyName
        MinPasswordLength               = $MinPasswordLength
        PasswordHistoryCount            = $PasswordHistoryCount
        ComplexityEnabled               = $ComplexityEnabled
        ReversibleEncryptionEnabled     = $ReversibleEncryptionEnabled
        LockoutThreshold                = $LockoutThreshold
        LockoutDurationMinutes          = $LockoutDurationMinutes
        LockoutObservationWindowMinutes = $LockoutObservationWindowMinutes
        MinPasswordAgeDays              = $MinPasswordAgeDays
        MaxPasswordAgeDays              = $MaxPasswordAgeDays
        Precedence                      = $Precedence
        AppliesTo                       = $AppliesTo
        Source                          = $Source
    }
}

function Convert-TimeSpanToDaysString {
    param($Value)
    if ($null -eq $Value) { return "" }

    try {
        return [string][Math]::Round(([TimeSpan]$Value).TotalDays, 2)
    }
    catch {
        return [string]$Value
    }
}

function Convert-TimeSpanToMinutesString {
    param($Value)
    if ($null -eq $Value) { return "" }

    try {
        return [string][Math]::Round(([TimeSpan]$Value).TotalMinutes, 2)
    }
    catch {
        return [string]$Value
    }
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Ensure-Directory -Path $OutDir

$csvPath = Join-Path $OutDir "Password_Policy_Audit_$timestamp.csv"

if ($MockMode) {
    Write-Host "[INFO] Running in MockMode (no AD required)" -ForegroundColor Cyan

    $rows = @(
        (New-PolicyRow -PolicyType "DefaultDomainPolicy" -PolicyName "Default Domain Policy" -MinPasswordLength "14" -PasswordHistoryCount "24" -ComplexityEnabled "True" -ReversibleEncryptionEnabled "False" -LockoutThreshold "5" -LockoutDurationMinutes "30" -LockoutObservationWindowMinutes "30" -MinPasswordAgeDays "1" -MaxPasswordAgeDays "90" -Precedence "" -AppliesTo "All domain users" -Source "MockMode"),
        (New-PolicyRow -PolicyType "FineGrainedPolicy" -PolicyName "Privileged Accounts PSO" -MinPasswordLength "20" -PasswordHistoryCount "24" -ComplexityEnabled "True" -ReversibleEncryptionEnabled "False" -LockoutThreshold "3" -LockoutDurationMinutes "60" -LockoutObservationWindowMinutes "30" -MinPasswordAgeDays "1" -MaxPasswordAgeDays "60" -Precedence "1" -AppliesTo "CN=Tier0_Admins,OU=Groups,DC=example,DC=local" -Source "MockMode"),
        (New-PolicyRow -PolicyType "FineGrainedPolicy" -PolicyName "Service Accounts PSO" -MinPasswordLength "32" -PasswordHistoryCount "10" -ComplexityEnabled "True" -ReversibleEncryptionEnabled "False" -LockoutThreshold "0" -LockoutDurationMinutes "0" -LockoutObservationWindowMinutes "0" -MinPasswordAgeDays "0" -MaxPasswordAgeDays "365" -Precedence "2" -AppliesTo "CN=Svc_Accounts,OU=Groups,DC=example,DC=local" -Source "MockMode")
    )
}
else {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Host "ERROR: ActiveDirectory module not found. Run this on a domain-joined machine with RSAT/AD tools installed, or use -MockMode." -ForegroundColor Red
        exit 1
    }

    $rows = @()

    try {
        $defaultPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop

        $rows += New-PolicyRow `
            -PolicyType "DefaultDomainPolicy" `
            -PolicyName "Default Domain Policy" `
            -MinPasswordLength ([string]$defaultPolicy.MinPasswordLength) `
            -PasswordHistoryCount ([string]$defaultPolicy.PasswordHistoryCount) `
            -ComplexityEnabled ([string]$defaultPolicy.ComplexityEnabled) `
            -ReversibleEncryptionEnabled ([string]$defaultPolicy.ReversibleEncryptionEnabled) `
            -LockoutThreshold ([string]$defaultPolicy.LockoutThreshold) `
            -LockoutDurationMinutes (Convert-TimeSpanToMinutesString $defaultPolicy.LockoutDuration) `
            -LockoutObservationWindowMinutes (Convert-TimeSpanToMinutesString $defaultPolicy.LockoutObservationWindow) `
            -MinPasswordAgeDays (Convert-TimeSpanToDaysString $defaultPolicy.MinPasswordAge) `
            -MaxPasswordAgeDays (Convert-TimeSpanToDaysString $defaultPolicy.MaxPasswordAge) `
            -Precedence "" `
            -AppliesTo "All domain users" `
            -Source "AD"
    }
    catch {
        $rows += New-PolicyRow `
            -PolicyType "DefaultDomainPolicy" `
            -PolicyName "<ERROR>" `
            -MinPasswordLength "" `
            -PasswordHistoryCount "" `
            -ComplexityEnabled "" `
            -ReversibleEncryptionEnabled "" `
            -LockoutThreshold "" `
            -LockoutDurationMinutes "" `
            -LockoutObservationWindowMinutes "" `
            -MinPasswordAgeDays "" `
            -MaxPasswordAgeDays "" `
            -Precedence "" `
            -AppliesTo $_.Exception.Message `
            -Source "AD"
    }

    try {
        $fgpps = Get-ADFineGrainedPasswordPolicy -Filter * -Properties * -ErrorAction Stop

        foreach ($pso in $fgpps) {
            $subjects = @()

            try {
                $subjects = Get-ADFineGrainedPasswordPolicySubject -Identity $pso.DistinguishedName -ErrorAction Stop |
                    Select-Object -ExpandProperty DistinguishedName
            }
            catch {
                $subjects = @("<SUBJECT LOOKUP FAILED>")
            }

            $appliesTo = if ($subjects -and $subjects.Count -gt 0) {
                $subjects -join "; "
            } else {
                "<NO SUBJECTS>"
            }

            $rows += New-PolicyRow `
                -PolicyType "FineGrainedPolicy" `
                -PolicyName $pso.Name `
                -MinPasswordLength ([string]$pso.MinPasswordLength) `
                -PasswordHistoryCount ([string]$pso.PasswordHistoryCount) `
                -ComplexityEnabled ([string]$pso.ComplexityEnabled) `
                -ReversibleEncryptionEnabled ([string]$pso.ReversibleEncryptionEnabled) `
                -LockoutThreshold ([string]$pso.LockoutThreshold) `
                -LockoutDurationMinutes (Convert-TimeSpanToMinutesString $pso.LockoutDuration) `
                -LockoutObservationWindowMinutes (Convert-TimeSpanToMinutesString $pso.LockoutObservationWindow) `
                -MinPasswordAgeDays (Convert-TimeSpanToDaysString $pso.MinPasswordAge) `
                -MaxPasswordAgeDays (Convert-TimeSpanToDaysString $pso.MaxPasswordAge) `
                -Precedence ([string]$pso.Precedence) `
                -AppliesTo $appliesTo `
                -Source "AD"
        }

        if (-not $fgpps -or $fgpps.Count -eq 0) {
            $rows += New-PolicyRow `
                -PolicyType "FineGrainedPolicy" `
                -PolicyName "<NONE FOUND>" `
                -MinPasswordLength "" `
                -PasswordHistoryCount "" `
                -ComplexityEnabled "" `
                -ReversibleEncryptionEnabled "" `
                -LockoutThreshold "" `
                -LockoutDurationMinutes "" `
                -LockoutObservationWindowMinutes "" `
                -MinPasswordAgeDays "" `
                -MaxPasswordAgeDays "" `
                -Precedence "" `
                -AppliesTo "" `
                -Source "AD"
        }
    }
    catch {
        $rows += New-PolicyRow `
            -PolicyType "FineGrainedPolicy" `
            -PolicyName "<ERROR>" `
            -MinPasswordLength "" `
            -PasswordHistoryCount "" `
            -ComplexityEnabled "" `
            -ReversibleEncryptionEnabled "" `
            -LockoutThreshold "" `
            -LockoutDurationMinutes "" `
            -LockoutObservationWindowMinutes "" `
            -MinPasswordAgeDays "" `
            -MaxPasswordAgeDays "" `
            -Precedence "" `
            -AppliesTo $_.Exception.Message `
            -Source "AD"
    }
}

$rows | Sort-Object PolicyType, PolicyName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$totalRows = $rows.Count
$defaultRows = ($rows | Where-Object { $_.PolicyType -eq "DefaultDomainPolicy" }).Count
$fgppRows = ($rows | Where-Object { $_.PolicyType -eq "FineGrainedPolicy" }).Count
$errorRows = ($rows | Where-Object { $_.PolicyName -eq "<ERROR>" }).Count

Write-Host ""
Write-Host "Password Policy Audit complete." -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Rows Exported:            $totalRows"
Write-Host "Default Policy Rows:      $defaultRows"
Write-Host "FGPP Rows:                $fgppRows"
Write-Host "Errors:                   $errorRows"
Write-Host ""
