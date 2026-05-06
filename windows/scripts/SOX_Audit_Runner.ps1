$ErrorActionPreference = "Continue"

$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = ".\output\sox_$RunStamp"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$IndexFile = Join-Path $OutputDir "SOX_Audit_Index_$RunStamp.txt"

$Tools = @(
    "Windows_Health_Check.ps1",
    "Patch_Dump.ps1",
    "Mapped_Drives_Report.ps1",
    "Password_Policy_Audit.ps1",
    "Inactive_Users_Audit.ps1",
    "Local_Admin_Audit.ps1",
    "AD_Privileged_Group_Audit.ps1",
    "AD_Description_Keyword_Audit.ps1",
    "Failed_Login_Audit.ps1",
    "SolarWinds_Agent_Audit.ps1",
    "Dynamics_GP_Database_Inventory.ps1",
    "Admin_Share_Audit.ps1",
    "Time_Sync_Audit.ps1",
    "Local_User_Audit.ps1",
    "Startup_Programs_Audit.ps1",
    "Scheduled_Tasks_Audit.ps1",
    "Service_Account_Audit.ps1",
    "Password_Reset_Audit.ps1",
    "AD_Group_Change_Audit.ps1",
    "Logon_Success_Audit.ps1"
)

"══════════════════════════════════════" | Set-Content $IndexFile
"SOX AUDIT EVIDENCE PACK" | Add-Content $IndexFile
"══════════════════════════════════════" | Add-Content $IndexFile
"" | Add-Content $IndexFile
"Generated: $Timestamp" | Add-Content $IndexFile
"Operator: $Operator" | Add-Content $IndexFile
"Computer: $Computer" | Add-Content $IndexFile
"Domain: $Domain" | Add-Content $IndexFile
"Script Version: $ScriptVersion" | Add-Content $IndexFile
"Output Folder: $OutputDir" | Add-Content $IndexFile
"" | Add-Content $IndexFile

foreach ($tool in $Tools) {
    $toolPath = Join-Path $PSScriptRoot $tool
    "Running: $tool" | Add-Content $IndexFile

    if (!(Test-Path $toolPath)) {
        "[MISSING] $toolPath" | Add-Content $IndexFile
        "" | Add-Content $IndexFile
        continue
    }

    try {
        if (Get-Command pwsh -ErrorAction SilentlyContinue) {
            & pwsh -ExecutionPolicy Bypass -File $toolPath
        }
        elseif (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
            & powershell.exe -ExecutionPolicy Bypass -File $toolPath
        }
        else {
            throw "No PowerShell runtime found."
        }

        "[OK] $tool completed" | Add-Content $IndexFile
    }
    catch {
        "[ERROR] $tool failed: $($_.Exception.Message)" | Add-Content $IndexFile
    }

    "" | Add-Content $IndexFile
}

"NOTE:" | Add-Content $IndexFile
"- Review each generated report before submitting as audit evidence." | Add-Content $IndexFile
"- Some AD reports require domain connectivity and appropriate permissions." | Add-Content $IndexFile
"" | Add-Content $IndexFile
"──────────────────────────────────────" | Add-Content $IndexFile
"© BayouFinds.com - All rights reserved." | Add-Content $IndexFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $IndexFile

Write-Host "SOX Audit Runner complete."
Write-Host "Index report: $IndexFile"
