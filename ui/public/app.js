const toolsEl = document.getElementById("tools");
const outputEl = document.getElementById("output");
const statusEl = document.getElementById("status");

async function loadTools() {
  const res = await fetch("/api/tools");
  const tools = await res.json();

  toolsEl.innerHTML = "";

  for (const tool of tools) {
    const card = document.createElement("article");
    card.className = "card";

    card.innerHTML = `
      <h3>${tool.label}</h3>
      <p>${tool.script}</p>
      <button data-tool="${tool.id}">Run Tool</button>
    `;

    toolsEl.appendChild(card);
  }

  document.querySelectorAll("button[data-tool]").forEach(btn => {
    btn.addEventListener("click", () => runTool(btn.dataset.tool, btn));
  });
}

async function runTool(toolId, button) {
  const allButtons = document.querySelectorAll("button");
  allButtons.forEach(b => b.disabled = true);

  statusEl.textContent = "Running...";
  outputEl.textContent = "Running tool. Stand by...";

  try {
    const res = await fetch(`/api/run/${toolId}`, { method: "POST" });
    const data = await res.json();

    statusEl.textContent = data.ok ? "Completed" : "Failed";

    outputEl.textContent =
`Tool: ${data.tool || toolId}
Script: ${data.script || ""}
Exit Code: ${data.exitCode ?? "N/A"}

--- STDOUT ---
${data.stdout || ""}

--- STDERR ---
${data.stderr || ""}

${data.error ? "--- ERROR ---\n" + data.error : ""}`;
  } catch (err) {
    statusEl.textContent = "Failed";
    outputEl.textContent = err.message;
  } finally {
    allButtons.forEach(b => b.disabled = false);
  }
}

loadTools();
