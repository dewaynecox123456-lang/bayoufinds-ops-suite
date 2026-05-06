const tools = {
  sox: {
    title: "SOX Audit Runner",
    purpose: "Generate a full audit evidence pack using authorized PowerShell scripts.",
    requirements: "Run from the Windows folder. Requires PowerShell and appropriate permissions.",
    command: "powershell -ExecutionPolicy Bypass -File .\\SOX_Audit_Runner.ps1",
    warning: "Review all generated reports before submitting as audit evidence."
  },
  access: {
    title: "Access Snapshot & Restore",
    purpose: "Capture and restore AD user group membership for termination hold, contractor conversion, rehire, and rollback workflows.",
    requirements: "Requires Active Directory module and domain connectivity.",
    command: "powershell -ExecutionPolicy Bypass -File .\\AD_Access_Snapshot_Export.ps1 -UserName jsmith",
    warning: "Restore operations should be reviewed before applying changes."
  },
  patch: {
    title: "Patch Validation",
    purpose: "Export installed patches and QFE evidence for audit validation.",
    requirements: "Run as administrator for best results.",
    command: "powershell -ExecutionPolicy Bypass -File .\\Patch_Dump.ps1",
    warning: "Patch reporting can vary by Windows version and update method."
  },
  ad: {
    title: "AD User / Role Audit",
    purpose: "Review user account details, group membership, and privileged role exposure.",
    requirements: "Requires AD module and permissions to query users and groups.",
    command: "powershell -ExecutionPolicy Bypass -File .\\AD_User_Audit_Report.ps1 -UserName jsmith",
    warning: "Use SamAccountName for reliable lookup."
  },
  localadmin: {
    title: "Local Admin Audit",
    purpose: "List local administrators for workstation or server access review.",
    requirements: "Run locally or with admin rights.",
    command: "powershell -ExecutionPolicy Bypass -File .\\Local_Admin_Audit.ps1",
    warning: "Validate unexpected administrators before taking action."
  },
  password: {
    title: "Policy-Based Password Reset Generator",
    purpose: "Generate temporary passwords that comply with baseline reset policy.",
    requirements: "No AD permissions required for generation.",
    command: "powershell -ExecutionPolicy Bypass -File .\\Password_Reset_Generator.ps1",
    warning: "Generated passwords are not written to disk by default."
  },
  help: {
    title: "Help / Support",
    purpose: "Open product help and troubleshooting documentation.",
    requirements: "Help file is included locally in the product bundle.",
    command: "start .\\help\\index.html",
    warning: "Support: support@bayoufinds.com"
  }
};

function showTool(key) {
  const t = tools[key];
  document.getElementById("content").innerHTML = `
    <div class="card">
      <h2>${t.title}</h2>
      <p><strong>Purpose:</strong> ${t.purpose}</p>
      <p><strong>Requirements:</strong> ${t.requirements}</p>
      <p class="note"><strong>Operator Note:</strong> ${t.warning}</p>
      <div class="command" id="cmd">${t.command}</div>
      <button class="copy" onclick="copyCommand()">Copy Command</button>
      <div class="footer">© BayouFinds.com — support@bayoufinds.com</div>
    </div>
  `;
}

function copyCommand() {
  const text = document.getElementById("cmd").innerText;
  navigator.clipboard.writeText(text);
  alert("Command copied.");
}

showTool("sox");
