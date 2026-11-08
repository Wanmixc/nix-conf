import { generateTitle as defaultGenerateTitle } from './title-request.mjs';

const MARKER = 'pi-auto-name-v1';
const MARKER_DATA = Object.freeze({ version: 1, status: 'claimed' });
const DEFAULT_DEADLINE_MS = 15_000;

function textFromMessage(message) {
  if (typeof message?.content === 'string') return message.content;
  if (!Array.isArray(message?.content)) return '';
  return message.content
    .filter((part) => part?.type === 'text' && typeof part.text === 'string')
    .map((part) => part.text)
    .join('');
}

function isUserMessage(message) {
  return message?.role === 'user';
}

function isSuccessfulAssistant(message) {
  return message?.role === 'assistant' &&
    message.stopReason === 'stop' &&
    textFromMessage(message).trim() !== '';
}

function entryMessage(entry) {
  return entry?.message ?? (entry?.type === 'message' ? entry.message : undefined);
}

function hasUserEntry(entries) {
  return entries.some((entry) => isUserMessage(entryMessage(entry)) || isUserMessage(entry));
}

function hasMarker(entries) {
  return entries.some((entry) => entry?.customType === MARKER);
}

function hasName(ctx) {
  return String(ctx.sessionManager.getSessionName?.() ?? '').trim() !== '';
}

function resolveEnabled(source, ctx) {
  const value = typeof source === 'function' ? source(ctx) : source;
  return value instanceof Promise ? value.then(Boolean) : Boolean(value);
}

/** Install once-only automatic session naming and return its settlement coordinator. */
export function installAutoNaming(pi, enabledSource, options = {}) {
  const generate = options.generateTitle ?? defaultGenerateTitle;
  const deadlineMs = options.deadlineMs ?? DEFAULT_DEADLINE_MS;
  let generation = 0;
  let session;
  let activeController;

  function warn(ctx) {
    ctx.ui?.notify?.('Pi: automatic chat naming unavailable; keeping current name.', 'warning');
  }

  function reset() {
    generation++;
    activeController?.abort();
    activeController = undefined;
    session = undefined;
  }

  pi.on('session_start', async (_event, ctx) => {
    reset();
    if (ctx.mode !== 'tui') return;
    const entries = ctx.sessionManager.getEntries?.() ?? [];
    session = {
      generation,
      sessionId: ctx.sessionManager.getSessionId(),
      enabled: await resolveEnabled(enabledSource, ctx),
      claimed: hasMarker(entries),
      priorUser: hasUserEntry(entries),
      manualName: hasName(ctx),
      candidate: false,
      userText: undefined,
      assistantText: undefined,
    };
  });

  pi.on('agent_start', async (_event, ctx) => {
    const current = session;
    if (!current || current.sessionId !== ctx.sessionManager.getSessionId() || ctx.mode !== 'tui' ||
        !current.enabled || current.claimed || current.priorUser || current.manualName) return;
    current.claimed = true;
    current.candidate = true;
    await pi.appendEntry?.(MARKER, { ...MARKER_DATA });
  });

  pi.on('message_start', (_event, ctx) => {
    const current = session;
    if (!current || current.sessionId !== ctx.sessionManager.getSessionId() || !current.candidate) return;
    const message = _event.message;
    if (isUserMessage(message) && current.userText === undefined)
      current.userText = textFromMessage(message);
  });

  pi.on('message_end', (_event, ctx) => {
    const current = session;
    if (!current || current.sessionId !== ctx.sessionManager.getSessionId() || !current.candidate) return;
    const message = _event.message;
    if (isUserMessage(message) && current.userText === undefined) {
      current.userText = textFromMessage(message);
    } else if (current.assistantText === undefined && isSuccessfulAssistant(message)) {
      current.assistantText = textFromMessage(message);
    }
  });

  pi.on('agent_end', (event, ctx) => {
    const current = session;
    if (!current || current.sessionId !== ctx.sessionManager.getSessionId() || !current.candidate || current.assistantText !== undefined) return;
    const assistant = event.messages?.findLast?.(isSuccessfulAssistant);
    if (assistant) current.assistantText = textFromMessage(assistant);
  });

  pi.on('session_shutdown', reset);

  async function finish(ctx, { failed = false, cancelled = false } = {}) {
    const current = session;
    if (!current || current.sessionId !== ctx.sessionManager.getSessionId() || current.generation !== generation) return;
    const attempt = current.candidate;
    current.candidate = false;
    if (!attempt || failed || cancelled || current.manualName ||
        current.userText === undefined || current.assistantText === undefined) return;

    const requestGeneration = generation;
    const controller = new AbortController();
    activeController = controller;
    const timeout = setTimeout(() => controller.abort(), deadlineMs);
    timeout.unref?.();
    try {
      const generated = generate(ctx, {
        userText: current.userText,
        assistantText: current.assistantText,
        signal: controller.signal,
      });
      const title = await Promise.race([
        generated,
        new Promise((_, reject) => {
          controller.signal.addEventListener('abort', () => reject(controller.signal.reason ?? new Error('Aborted')), { once: true });
        }),
      ]);
      if (generation !== requestGeneration || session !== current || controller.signal.aborted) return;
      if (hasName(ctx)) return;
      await pi.setSessionName?.(title);
    } catch {
      if (generation === requestGeneration && !controller.signal.aborted) warn(ctx);
    } finally {
      clearTimeout(timeout);
      if (activeController === controller) activeController = undefined;
    }
  }

  return finish;
}
