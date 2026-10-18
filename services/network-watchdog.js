// ~/.config/opencode/plugins/network-watchdog.js
import { Plugin } from "@opencode/plugin";
import { exec } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

export default Plugin.define({
  id: "network-watchdog",
  async setup(ctx) {
    let isOnline = true;
    let wasOffline = false;
    let activeSessionID = null;
    let timer = null;

    const PING_INTERVAL_MS = 5000;
    const CONFIG_DIR = path.join(os.homedir(), ".config", "opencode");
    const STATE_FILE = path.join(CONFIG_DIR, ".watchdog-state");

    function isEnabled() {
      return fs.existsSync(STATE_FILE);
    }

    function notifyUser(title, message, variant = "info") {
      if (ctx.tui?.showToast) {
        try {
          ctx.tui.showToast({ body: { title, message, variant } });
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
          if (ctx.session?.get) {
            const res = await ctx.session.get({ path: { id: sessionId } });
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

      if (!targetSession && ctx.session?.list) {
        try {
          const sessions = await ctx.session.list();
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
        if (ctx.session?.abort) {
          await ctx.session.abort({ path: { id: targetSession } }).catch(() => {});
        }
        await waitForSessionIdle(targetSession);

        if (ctx.session?.prompt) {
          await ctx.session.prompt({
            path: { id: targetSession },
            body: { parts: [{ type: "text", text: "continue" }] },
          });
        }
        wasOffline = false;
      } catch (err) {
        notifyUser("Watchdog Error", `Recovery failed: ${err.message}`, "error");
      }
    }

    // Register /network-watchdog <on|off> command
    await ctx.command.transform((editor) => {
      editor.add({
        name: "network-watchdog",
        description: "Toggle network watchdog background monitor (on|off)",
        execute: async ({ sessionID, prompt, delivery }) => {
          const args = prompt.text.trim();
          if (args === "on") {
            fs.writeFileSync(STATE_FILE, "");
            await ctx.session.prompt({
              sessionID,
              text: "Network watchdog enabled.",
              delivery,
            });
          } else if (args === "off") {
            fs.unlinkSync(STATE_FILE);
            await ctx.session.prompt({
              sessionID,
              text: "Network watchdog disabled.",
              delivery,
            });
          } else {
            await ctx.session.prompt({
              sessionID,
              text: "Usage: /network-watchdog <on|off>",
              delivery,
            });
          }
        },
      });
    });

    // Subscribe to session events to track active session
    const eventController = new AbortController();
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: eventController.signal })) {
        const extractedID =
          event.properties?.sessionID ||
          event.properties?.id ||
          event.payload?.sessionID ||
          event.sessionID ||
          (event.type === "session.created" ? event.properties?.id : null);

        if (extractedID) {
          activeSessionID = extractedID;
        }
      }
    })();

    // Start network monitoring timer
    timer = setInterval(async () => {
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

    // Return cleanup function
    return () => {
      clearInterval(timer);
      eventController.abort();
    };
  },
});