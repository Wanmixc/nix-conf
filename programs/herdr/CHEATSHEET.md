# herdr Cheatsheet

Terminal multiplexer. Keys below reflect **your** config in
[`programs/herdr/config.toml`](../programs/herdr/config.toml).

> **Prefix = `Ctrl+a`** — press it, release, then press the next key.
> Notation: `⟨p⟩ x` means "prefix, then `x`".

---

## Session

| Keys | Action |
|------|--------|
| `⟨p⟩ q` | Detach (leave session running) |
| `⟨p⟩ r` | Reload config (`~/.config/herdr/config.toml`) |
| `⟨p⟩ b` | Toggle sidebar |

## Plugins (herdr-plus)

| Keys | Action |
|------|--------|
| `⟨p⟩ p` | Herdr Plus: Projects picker |
| `⟨p⟩ P` | Quick Actions picker (`prefix+shift+p`, commented out by default) |

Configured via `[[keys.command]]` in `config.toml`; plugin itself lives in
[`programs/herdr-plus.nix`](../programs/herdr-plus.nix).

## Tabs

| Keys | Action |
|------|--------|
| `⟨p⟩ c` | New tab |
| `⟨p⟩ 1`…`9` | Switch to tab N |

## Panes — split & close

| Keys | Action |
|------|--------|
| `⟨p⟩ \|` | Split vertical (side by side) |
| `⟨p⟩ -` | Split horizontal (stacked) |
| `⟨p⟩ x` | Close pane (confirm prompt is on) |
| `⟨p⟩ z` | Zoom / un-zoom pane (fullscreen toggle) |

## Panes — focus (vim h/j/k/l)

| Keys | Action |
|------|--------|
| `⟨p⟩ h` | Focus pane left |
| `⟨p⟩ j` | Focus pane down |
| `⟨p⟩ k` | Focus pane up |
| `⟨p⟩ l` | Focus pane right |

## Panes — swap (move pane in layout)

| Keys | Action |
|------|--------|
| `⟨p⟩ H` | Swap pane left  (`prefix+shift+h`) |
| `⟨p⟩ J` | Swap pane down  (`prefix+shift+j`) |
| `⟨p⟩ K` | Swap pane up    (`prefix+shift+k`) |
| `⟨p⟩ L` | Swap pane right (`prefix+shift+l`) |

## Resize mode

| Keys | Action |
|------|--------|
| `⟨p⟩ R` | Enter resize mode (`prefix+shift+r`) |
| `h/j/k/l` | Resize in the given direction (while in mode) |
| `Esc` | Exit resize mode |

## Copy mode

| Keys | Action |
|------|--------|
| `⟨p⟩ [` | Enter copy/scrollback mode |
| `h/j/k/l` | Navigate (no prefix, while in mode) |
| `Esc` / `q` | Exit copy mode |

---

## Config reference (`programs/herdr/config.toml`)

| Setting | Value | Meaning |
|---------|-------|---------|
| `onboarding` | `false` | Skip first-run wizard |
| `update.version_check` | `false` | No update checks |
| `terminal.shell_mode` | `"auto"` | Auto-detect shell |
| `terminal.new_cwd` | `"follow"` | New panes/tabs open in current pane's cwd |
| `theme.name` | `"terminal"` | Inherit terminal colors |
| `ui.mouse_capture` | `true` | Mouse selects/focuses panes |
| `ui.confirm_close` | `true` | Ask before closing a pane |
| `ui.prompt_new_tab_name` | `false` | Don't prompt for tab name |

Edit keys in `programs/herdr/config.toml` → rebuild home-manager → `⟨p⟩ r` to reload.
