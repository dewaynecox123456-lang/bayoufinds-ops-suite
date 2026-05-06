$ErrorActionPreference = "Stop"

function Show-Banner {
    Write-Host ""
    Write-Host "====================================================="
    Write-Host "        BayouFinds Ops Suite — Windows Launcher"
    Write-Host "====================================================="
    Write-Host ""
}

function Ensure-License {
    
if ($env:USERPROFILE) {
    $basePath = $env:USERPROFILE
} else {
    $basePath = $env:HOME
}

$licenseDir = Join-Path $basePath ".bayoufinds"

    $licensePath = Join-Path $licenseDir "license.key"

    if (!(Test-Path $licenseDir)) {
        New-Item -ItemType Directory -Force -Path $licenseDir | Out-Null
    }

    if (!(Test-Path $licensePath)) {
        Write-Host "[INFO] No license key found."
        $enteredKey = Read-Host "Enter your license key"
        if (-not $enteredKey) {
            Write-Host "[ERROR] No license key entered."
            exit 1
        }
        Set-Content -Path $licensePath -Value $enteredKey
    }

    Write-Host "[OK] License verified."
    Write-Host ""
}

function Run-Tool {
    param([string]$ScriptName)

    $scriptPath = Join-Path $PSScriptRoot "scripts" $ScriptName
if (!(Test-Path $scriptPath)) {
    $scriptPath = Join-Path $PSScriptRoot $ScriptName
}

    if (!(Test-Path $scriptPath)) {
        Write-Host "[ERROR] Script not found: $scriptPath" -ForegroundColor Red
        Read-Host "Press Enter"
        return
    }

    Write-Host "[INFO] Running $scriptPath ..." -ForegroundColor Cyan

    try {
        if (Get-Command pwsh -ErrorAction SilentlyContinue) {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath
        }
        elseif (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
        }
        else {
            Write-Host "[ERROR] No PowerShell runtime found." -ForegroundColor Red
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] Script exited with code $LASTEXITCODE" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ERROR] Failed to run ${ScriptName}: $($_.Exception.Message)" -ForegroundColor Red
    }

    Read-Host "Press Enter"
}


function Show-Help {
    Start-Process "help\index.html"
}

function Show-About {
    Write-Host ""
    Write-Host "BayouFinds Ops Suite"
    Write-Host ""
    Write-Host "Support: support@bayoufinds.com"
    Write-Host "https://bayoufinds.com"
    Write-Host ""
    Read-Host "Press Enter"
}

Show-Banner
Ensure-License

while ($true) {
    Clear-Host
    Show-Banner

   Write-Host ""
Write-Host "==================== SYSTEM ====================" -ForegroundColor Cyan
Write-Host "[1]  Windows Health Check"
Write-Host "[4]  Patch Dump"
Write-Host "[5]  Mapped Drives Report"

Write-Host ""
Write-Host "==================== IDENTITY ==================" -ForegroundColor Green
Write-Host "[7]  AD User Audit Report"
Write-Host "[8]  AD Role Audit Report"
Write-Host "[9]  AD Privileged Group Audit"
Write-Host "[12] Inactive Users Audit"
Write-Host "[13] Local Admin Audit"

Write-Host ""
Write-Host "==================== AUTH ======================" -ForegroundColor Yellow
Write-Host "[16] Failed Login / Brute Force Audit"
Write-Host "[17] Logon Success Audit"
Write-Host "[18] AD Group Change Audit"
Write-Host "[19] Password Change / Reset Audit"

Write-Host ""
Write-Host "==================== OPERATIONS ================" -ForegroundColor Magenta
Write-Host "[20] Service Account Audit"
Write-Host "[21] Scheduled Tasks Audit"
Write-Host "[22] Startup Programs Audit"
Write-Host "[23] Local User Audit"
Write-Host "[24] Time Sync Audit"
Write-Host "[25] Admin Share Audit"
Write-Host "[26] SolarWinds Agent Audit"

Write-Host ""
Write-Host "==================== AUDIT =====================" -ForegroundColor Red
Write-Host "[14] SOX Audit Runner (Full Evidence Pack)"
Write-Host "[15] AD Description Keyword Audit"

Write-Host ""
Write-Host "==================== DATA ======================" -ForegroundColor DarkCyan
Write-Host "[27] Dynamics GP Database Inventory"

Write-Host ""
Write-Host "[H] Help"
Write-Host "[A] About / Support"
Write-Host "[0] Exit"
    
    Write-Host ""

    $choice = Read-Host "Select an option"
    $choice = $choice.Trim().ToUpper()

    switch ($choice) {
        "1"  { Run-Tool "Windows_Health_Check.ps1" }
        "2"  { Run-Tool "AD_Access_Snapshot_Export.ps1" }
        "3"  { Run-Tool "AD_Access_Snapshot_Restore.ps1" }
        "4"  { Run-Tool "Patch_Dump.ps1" }
        "5"  { Run-Tool "Mapped_Drives_Report.ps1" }
        "6"  { Run-Tool "Password_Reset_Generator.ps1" }
        "7"  { Run-Tool "AD_User_Audit_Report.ps1" }
        "8"  { Run-Tool "AD_Role_Audit_Report.ps1" }
        "9"  { Run-Tool "AD_Privileged_Group_Audit.ps1" }
        "10" { Run-Tool "Password_Policy_Audit.ps1" }
        "11" { Run-Tool "AD_Termination_Date_Audit.ps1" }
        "12" { Run-Tool "Inactive_Users_Audit.ps1" }
        "13" { Run-Tool "Local_Admin_Audit.ps1" }
        "14" { Run-Tool "SOX_Audit_Runner.ps1" }
        "15" { Run-Tool "AD_Description_Keyword_Audit.ps1" }
        "16" { Run-Tool "Failed_Login_Audit.ps1" }
        "H"  { Show-Help }
        "17" { Run-Tool "Logon_Success_Audit.ps1" }
        "18" { Run-Tool "AD_Group_Change_Audit.ps1" }
        "19" { Run-Tool "Password_Reset_Audit.ps1" }
        "20" { Run-Tool "Service_Account_Audit.ps1" }
        "21" { Run-Tool "Scheduled_Tasks_Audit.ps1" }
        "22" { Run-Tool "Startup_Programs_Audit.ps1" }
        "23" { Run-Tool "Local_User_Audit.ps1" }
        "24" { Run-Tool "Time_Sync_Audit.ps1" }
        "25" { Run-Tool "Admin_Share_Audit.ps1" }
        "26" { Run-Tool "SolarWinds_Agent_Audit.ps1" }
        "27" { Run-Tool "Dynamics_GP_Database_Inventory.ps1" }
        "A"  { Show-About }
        "0"  { Write-Host "Exiting BayouFinds Ops Suite..."; exit 0 }
        default {
            Write-Host "[WARN] Invalid selection"
            Read-Host "Press Enter"
        }
    }
}
