const express = require("express");
const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 8788;

const ROOT = path.resolve(__dirname, "..");
const WINDOWS_DIR = path.join(ROOT, "windows");

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

const tools = {
  userAudit: {
    label: "AD User Audit",
    script: "AD_User_Audit_Report.ps1",
    args: ["-MockMode"]
  },
  roleAudit: {
    label: "AD Role Audit",
    script: "AD_Role_Audit_Report.ps1",
    args: []
  },
  privilegedAudit: {
    label: "Privileged Group Audit",
    script: "AD_Privileged_Group_Audit.ps1",
    args: ["-MockMode"]
  },
  passwordPolicy: {
    label: "Password Policy Audit",
    script: "Password_Policy_Audit.ps1",
    args: ["-MockMode"]
  },
  terminationAudit: {
    label: "Termination Date Audit",
    script: "AD_Termination_Date_Audit.ps1",
    args: ["-MockMode", "-TermDate", "2026-04-22"]
  },
  inactiveUsers: {
    label: "Inactive Users Audit",
    script: "AD_Inactive_Users_Report.ps1",
    args: ["-MockMode", "-DaysInactive", "90"]
  },
  localAdmin: {
    label: "Local Admin Audit",
    script: "Local_Admin_Audit_Report.ps1",
    args: ["-MockMode"]
  }
};

function getPowerShellCommand() {
  if (process.platform === "win32") return "powershell.exe";
  return "pwsh";
}

app.get("/api/tools", (req, res) => {
  res.json(
    Object.entries(tools).map(([id, tool]) => ({
      id,
      label: tool.label,
      script: tool.script
    }))
  );
});

app.post("/api/run/:toolId", (req, res) => {
  const tool = tools[req.params.toolId];

  if (!tool) {
    return res.status(404).json({ ok: false, error: "Unknown tool." });
  }

  const scriptPath = path.join(WINDOWS_DIR, tool.script);

  if (!fs.existsSync(scriptPath)) {
    return res.status(404).json({
      ok: false,
      error: `Script not found: ${scriptPath}`
    });
  }

  const ps = getPowerShellCommand();
  const args = ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...tool.args];

  const child = spawn(ps, args, {
    cwd: ROOT,
    shell: false
  });

  let stdout = "";
  let stderr = "";

  child.stdout.on("data", data => {
    stdout += data.toString();
  });

  child.stderr.on("data", data => {
    stderr += data.toString();
  });

  child.on("error", err => {
    res.status(500).json({
      ok: false,
      tool: tool.label,
      error: err.message,
      hint: "PowerShell was not found. On Fedora toolbox, make sure pwsh is installed and in PATH."
    });
  });

  child.on("close", code => {
    res.json({
      ok: code === 0,
      tool: tool.label,
      script: tool.script,
      exitCode: code,
      stdout,
      stderr
    });
  });
});

app.listen(PORT, () => {
  console.log(`BayouFinds AD Audit UI running at http://localhost:${PORT}`);
});
