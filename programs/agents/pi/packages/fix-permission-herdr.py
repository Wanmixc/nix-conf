#!/usr/bin/env python3
"""Bracket pi-permission-system's user dialog with Herdr state events."""

import sys
from pathlib import Path

path = Path(sys.argv[1]) / "@gotgenes/pi-permission-system/src/authority/local-user-authorizer.ts"
source = path.read_text()
old = '''    return this.deps.requestPermissionDecision(
      {
        mode: this.deps.mode,
        ui: this.deps.ui,
        doublePressToConfirm:
          this.deps.getPromptPreferences().doublePressToConfirm,
      },
      details.forwarding
        ? "Permission Required (Subagent)"
        : "Permission Required",
      details.message,
      buildRequestOptions(details),
    );'''
new = '''    try {
      this.deps.events.emit("herdr:blocked", { active: true, label: "Permission required" });
    } catch {
      // State reporting must not prevent the permission dialog.
    }
    return Promise.resolve().then(() => this.deps.requestPermissionDecision(
      {
        mode: this.deps.mode,
        ui: this.deps.ui,
        doublePressToConfirm:
          this.deps.getPromptPreferences().doublePressToConfirm,
      },
      details.forwarding
        ? "Permission Required (Subagent)"
        : "Permission Required",
      details.message,
      buildRequestOptions(details),
    )).finally(() => {
      try {
        this.deps.events.emit("herdr:blocked", { active: false });
      } catch {
        // State reporting must not alter the permission decision.
      }
    });'''
if source.count(old) != 1:
    raise SystemExit(f"Unexpected permission extension source: {path}")
path.write_text(source.replace(old, new, 1))
