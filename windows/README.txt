BayouFinds Ops Suite v1.0

START HERE
----------
1) Extract the ZIP.
2) Double-click RUN_ME.cmd on Windows.
3) Select [14] SOX Audit Runner for the full evidence pack.
4) Review generated reports in the output folder.

PURPOSE
-------
BayouFinds Ops Suite helps IT teams generate audit-ready evidence for:
- Active Directory access reviews
- Privileged access audits
- Login and lockout activity
- Patch validation
- Monitoring coverage
- Dynamics GP / SQL inventory visibility

ENVIRONMENT REQUIREMENTS
------------------------
This toolkit is designed for:

- Windows 10 / 11
- Windows Server
- PowerShell 5.1 or PowerShell 7+
- Administrator privileges recommended

Some modules require:

- ActiveDirectory / RSAT tools
- GroupPolicy module
- SQLServer module for Dynamics GP / SQL inventory
- Domain connectivity for AD scripts
- Appropriate delegated permissions

IMPORTANT NOTE
--------------
Running this toolkit on Linux or macOS may launch the menu, but many audit scripts will return partial results or expected errors because they depend on Windows, Active Directory, Windows Event Logs, registry access, or server modules.

OUTPUT
------
Reports are written to:

.\output\

SUPPORT
-------
support@bayoufinds.com
https://bayoufinds.com

© BayouFinds.com - All rights reserved.
