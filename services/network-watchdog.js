// ~/.config/opencode/plugins/network-watchdog.js
import { exec } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

export const NetworkWatchdogPlugin = async ({ client }) => {
  let isOnline = true;
  let wasOffline = false;
  let activeSessionID = null;

  const PING_INTERVAL_MS = 5000;
  const CONFIG_DIR = path.join(os.homedir(), ".config", "opencode");
  const STATE_FILE = path.join(CONFIG_DIR, ".watchdog-state");

  function isEnabled() {
    return fs.existsSync(STATE_FILE);
  }

  function notifyUser(title, message, variant = "info") {
    if (client.tui?.showToast) {
      try {
        client.tui.showToast({ body: { title, message, variant } });
        return;
      } catch {}
    }

    const urgency = variant === "error" || variant === "warning" ? "critical" : "normal";
    const cmd =
      process.platform === "linux"
        ? `notify-send -u ${urgency} "${title}" "${message}"`
        : process.platform === "darwin"
        ? `osascript -e 'display notification "${message}" with title "${title}"'`
        : null;

    if (cmd) exec(cmd, () => {});
  }

  async function checkNetwork() {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2000);
      const res = await fetch("https://1.1.1.1", { method: "HEAD", signal: controller.signal });
      clearTimeout(timeoutId);
      return res.ok;
    } catch {
      return false;
    }
  }

  async function waitForSessionIdle(sessionId, maxAttempts = 10) {
    for (let i = 0; i < maxAttempts; i++) {
      try {
        if (client.session?.get) {
          const res = await client.session.get({ path: { id: sessionId } });
          const status = res.data?.status || res.status;
          if (status !== "busy" && status !== "running") return true;
        }
      } catch {}
      await new Promise((r) => setTimeout(r, 500));
    }
    return true;
  }

  async function handleReconnection() {
    let targetSession = activeSessionID;

    if (!targetSession && client.session?.list) {
      try {
        const sessions = await client.session.list();
        const active = sessions.data?.find((s) => s.status === "busy" || s.active);
        if (active) targetSession = active.id;
      } catch {}
    }

    if (!targetSession) {
      notifyUser("Network Watchdog", "Reconnected, but no active session found.", "warning");
      wasOffline = false;
      return;
    }

    notifyUser("Network Watchdog", "Internet restored! Resuming session...", "info");

    try {
      if (client.session?.abort) {
        await client.session.abort({ path: { id: targetSession } }).catch(() => {});
      }
      await waitForSessionIdle(targetSession);

      if (client.session?.prompt) {
        await client.session.prompt({
          path: { id: targetSession },
          body: { parts: [{ type: "text", text: "continue" }] },
        });
      }
      wasOffline = false;
    } catch (err) {
      notifyUser("Watchdog Error", `Recovery failed: ${err.message}`, "error");
    }
  }

  const timer = setInterval(async () => {
    if (!isEnabled()) return;

    const reachable = await checkNetwork();

    if (!reachable) {
      if (isOnline) {
        notifyUser("Network Watchdog", "Connection dropped. Waiting...", "warning");
      }
      isOnline = false;
      wasOffline = true;
    } else {
      isOnline = true;
      if (wasOffline) {
        await handleReconnection();
      }
    }
  }, PING_INTERVAL_MS);

  return {
    // Register native commands dynamically in OpenCode's runtime configuration
    config: async (config) => {
      config.command = config.command || {};

      // Registers /network-watchdog <on|off>
      config.command["network-watchdog"] = {
        description: "Toggle network watchdog background monitor (on|off)",
        template: `!\`if [ "$ARGUMENTS" = "on" ]; then touch "${STATE_FILE}" && echo "Network watchdog enabled."; elif [ "$ARGUMENTS" = "off" ]; then rm -f "${STATE_FILE}" && echo "Network watchdog disabled."; else echo "Usage: /network-watchdog <on|off>"; fi\``
      };
    },

    event: async ({ event }) => {
      const extractedID =
        event.properties?.sessionID ||
        event.properties?.id ||
        event.payload?.sessionID ||
        event.sessionID ||
        (event.type === "session.created" ? event.properties?.id : null);

      if (extractedID) {
        activeSessionID = extractedID;
      }
    },

    dispose: () => {
      clearInterval(timer);
    },
  };
};

export default NetworkWatchdogPlugin;
