import { readFile } from 'node:fs/promises';
import { isAbsolute, relative, sep } from 'node:path';
import { hostname, homedir } from 'node:os';

// Keep metadata on one line and well below ntfy's 4096-byte attachment threshold.
function metadataLine(value, fallback) {
  const text = String(value ?? '').replace(/[\s\u0000-\u001f\u007f-\u009f]+/gu, ' ').trim();
  return Array.from(text || fallback).slice(0, 240).join('');
}

/** Bind a session-scoped notifier. Dependencies isolate clock, filesystem and HTTP. */
export function installNotifications(pi, configSource, dependencies = {}) {
  const now = dependencies.now ?? (() => performance.now());
  const read = dependencies.readFile ?? readFile;
  const publish = dependencies.fetch ?? globalThis.fetch;
  const beforeNotify = dependencies.beforeNotify ?? (async () => {});
  const isInterrupt = dependencies.isInterrupt ?? (() => false);
  const server = metadataLine(dependencies.serverName ?? hostname(), 'Unknown server');
  const home = dependencies.homeDirectory ?? homedir();
  const pending = new Set();
  let config;
  let run;
  let generation = 0;
  let removeInput;

  const warn = (ctx) => ctx.ui.notify('ntfy: notification unavailable; check local configuration or connectivity.', 'warning');

  function reset() {
    generation++;
    config = undefined;
    run = undefined;
    removeInput?.();
    removeInput = undefined;
    for (const controller of pending) controller.abort();
    pending.clear();
  }

  pi.on('session_start', async (_event, ctx) => {
    reset();
    if (ctx.mode !== 'tui') return;
    try {
      const value = typeof configSource === 'function' ? await configSource() : configSource;
      if (value?.notificationsEnabled === false) {
        config = { notificationsEnabled: false };
        return;
      }
      if (!value || !Number.isFinite(value.thresholdSeconds) || value.thresholdSeconds < 0 ||
          typeof value.secretsFile !== 'string' || !isAbsolute(value.secretsFile)) {
        throw new Error('Invalid configuration');
      }
      config = { notificationsEnabled: true, thresholdSeconds: value.thresholdSeconds, secretsFile: value.secretsFile };
      removeInput = ctx.ui.onTerminalInput((data) => {
        // Retry/compaction cancellation can leave a stale error/stop message.
        // While the agent is active, its abort signal is authoritative instead:
        // Esc may merely dismiss autocomplete or a permission dialog.
        if (run?.ended && isInterrupt(data)) run.cancelled = true;
      });
    } catch {
      warn(ctx);
    }
  });

  pi.on('agent_start', (_event, ctx) => {
    if (!config || ctx.mode !== 'tui') return;
    run ??= { startedAt: now() };
    run.ended = false;
    run.cancelled = false;
    run.reason = undefined;
    run.signal = ctx.signal;
  });

  pi.on('agent_end', (event, ctx) => {
    if (!run) return;
    run.ended = true;
    run.signal ??= ctx.signal;
    run.reason = event.messages.findLast((message) => message.role === 'assistant')?.stopReason;
  });

  pi.on('agent_settled', (_event, ctx) => {
    if (!run || !config || ctx.mode !== 'tui' || !ctx.isIdle()) return;
    const completed = run;
    run = undefined;
    const elapsed = now() - completed.startedAt;
    const cancelled = completed.cancelled || completed.signal?.aborted || completed.reason === 'aborted';
    const failed = completed.reason === 'error' || completed.reason === 'length' || !completed.reason;
    const sessionGeneration = generation;
    void settle(ctx, { elapsed, cancelled, failed, sessionGeneration });
  });

  pi.on('session_shutdown', reset);

  async function settle(ctx, { elapsed, cancelled, failed, sessionGeneration }) {
    try {
      await beforeNotify(ctx, { failed, cancelled });
    } catch {
      // Naming is best-effort; notification delivery still uses the current name.
    }
    if (generation !== sessionGeneration || !config) return;
    if (!config.notificationsEnabled || cancelled || elapsed / 1000 <= config.thresholdSeconds) return;
    const title = `${failed ? 'Pi error' : 'Pi finished'} — ${server}`;
    const cwd = ctx.cwd;
    const fromHome = relative(home, cwd);
    const folder = fromHome === '' ? '~'
      : !isAbsolute(fromHome) && fromHome !== '..' && !fromHome.startsWith(`..${sep}`)
        ? `~/${fromHome}` : cwd;
    const body = [
      `Server: ${server}`,
      `Folder: ${metadataLine(folder, 'Unknown folder')}`,
      `Chat: ${metadataLine(ctx.sessionManager.getSessionName(), 'Unnamed chat')}`,
      `Duration: ${Math.floor(elapsed / 1000)}s`,
      `Status: ${failed ? 'Error' : 'Finished responding'}`,
    ].join('\n');
    void deliver(config.secretsFile, title, body, ctx);
  }

  async function deliver(secretsFile, title, body, ctx) {
    const currentGeneration = generation;
    const controller = new AbortController();
    pending.add(controller);
    // Bound the secret read as well as HTTP. Never retain a URL in session state.
    const timeout = setTimeout(() => controller.abort(), 5000);
    timeout.unref?.();
    try {
      const secrets = JSON.parse(await read(secretsFile, { encoding: 'utf8', signal: controller.signal }));
      if (controller.signal.aborted) return;
      if (typeof secrets?.ntfy_url !== 'string') throw new Error('Missing URL');
      const url = new URL(secrets.ntfy_url);
      if (url.protocol !== 'https:' || url.username || url.password || url.hash ||
          !url.pathname.replaceAll('/', '')) throw new Error('Invalid URL');
      const response = await publish(url.href, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          // ntfy supports RFC 2047; Node fetch cannot send an em dash verbatim.
          Title: `=?UTF-8?B?${Buffer.from(title, 'utf8').toString('base64')}?=`,
        },
        body,
        redirect: 'error',
        signal: controller.signal,
      });
      // Discard server content without buffering it or exposing it in diagnostics.
      await response.body?.cancel();
      if (!response.ok) throw new Error('Publish failed');
    } catch {
      if (generation === currentGeneration) warn(ctx);
    } finally {
      clearTimeout(timeout);
      pending.delete(controller);
    }
  }
}
