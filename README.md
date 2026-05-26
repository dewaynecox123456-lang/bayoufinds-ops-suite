# BayouFinds Ops Suite v1.0

![BayouFinds Ops Suite](./screenshots/Audit.png)

BayouFinds Ops Suite is a lightweight Windows audit and SOX evidence toolkit for Active Directory, Windows Server, and SMB operations teams.

The suite is built around portable PowerShell scripts that collect readable CSV and TXT evidence for recurring audit, troubleshooting, access review, and compliance-prep workflows.

## Built For

- System administrators
- IT operations teams
- Windows Server environments
- Active Directory teams
- MSPs and consultants
- Compliance and SOX evidence preparation
- Field use during incidents, reviews, and maintenance windows

## What It Does

- Active Directory user and role audits
- Privileged group visibility
- Local admin and local user review
- Authentication success/failure reporting
- Account lockout tracking for event 4740
- Password policy and password reset auditing
- Patch, scheduled task, startup program, admin share, and time sync checks
- Dynamics GP / SQL inventory visibility
- Timestamped CSV and TXT exports suitable for evidence packets

## Current Modules

- AD User Audit Report
- AD Role Audit Report
- AD Privileged Group Audit
- AD Group Change Audit
- AD Description Keyword Audit
- AD Termination Date Audit
- AD Access Snapshot Export / Restore
- Password Policy Audit
- Password Change / Reset Audit
- Password Reset Generator
- Lockout Hunter (4740)
- Failed Login / Brute Force Audit
- Logon Success Audit
- Local Admin Audit
- Local User Audit
- Inactive Users Audit
- Windows Health Check
- Patch Dump
- Mapped Drives Report
- Time Sync Audit
- Scheduled Tasks Audit
- Startup Programs Audit
- Service Account Audit
- Admin Share Audit
- SolarWinds Agent Audit
- SOX Audit Runner
- Dynamics GP Database Inventory

## Requirements

- Windows PowerShell or PowerShell 7+
- Windows host for Windows-specific inventory commands
- RSAT / ActiveDirectory PowerShell module for AD reports
- Domain connectivity and appropriate permissions for domain and Security log audits

Some scripts include mock or local-only behavior, but AD and Security event log reports should be run from an operator workstation or server with the required modules and permissions.

## Running The Toolkit

From the `windows` folder, launch:

```powershell
.\run-windows.ps1
```

Reports are written under:

```text
windows/output
```

Exports are timestamped so repeated runs do not overwrite prior evidence.

## Screenshots

### Hero Image

![Hero Image](./screenshots/Audit.png)

### Audit Report Example

![Audit Report](./screenshots/image.png)

### Audit Report Example

![BayouFinds Ops Suite](./screenshots/image2.png)

## Operator Notes

- Review generated reports before submitting them as audit evidence.
- Some reports may return no records if auditing is not enabled, logs have rolled over, or the current user lacks permission.
- AD reports require the ActiveDirectory module and domain access.
- The toolkit is designed for local execution and does not introduce cloud dependencies or telemetry.

## Full Toolkit

The packaged toolkit and release downloads are available here:

https://bayoufinds.com/b/fSyzm
