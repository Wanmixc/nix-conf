# Home Manager

Personal multi-machine [Home Manager](https://nix-community.github.io/home-manager/) configuration for:

- `cachyos-nix`
- `wsl`
- `vps`

`programs/` groups modules by area (`shell/`, `herdr/`, `agents/`, `media/`, `desktop/`). A module with supporting files is a directory with `default.nix`; a single-file module is a plain `.nix` file. Hosts compose modules through `profiles/`, and locally built packages live in `pkgs/` and are added to `pkgs` through an overlay.

## Host Targets

Available Home Manager flake targets:

- `wanmixc-cachyos-nix`
- `wanmixc-wsl`
- `wanmixc-vps`

## Rules

AI tool policy:

- `cachyos-nix` -> `codex`, `claude-code`, `ollama`, `pi-coding-agent`
- `wsl` -> `codex`, `claude-code`, `pi-coding-agent`
- `vps` -> `pi-coding-agent`
- Claude Code is split into `programs/agents/claude-code.nix` so it can be imported only on selected machines.

Neovim policy:

- one shared Neovim config
- source of truth is the `programs/nvim/` folder in this repo

## Repository Structure

```text
.
├── .gitignore
├── flake.nix
├── flake.lock
├── home.nix
├── hosts/
│   ├── cachyos-nix.nix
│   ├── wsl.nix
│   └── vps.nix
├── profiles/
│   ├── common.nix   # every host
│   ├── agents.nix   # codex, claude-code
│   └── desktop.nix  # desktop apps, xdg, mpd, rmpc, ollama
├── pkgs/
│   ├── default.nix  # overlay
│   ├── neossh.nix
│   ├── notion-mcp-server/
│   └── pi-coding-agent/
├── programs/
│   ├── base.nix
│   ├── devtools.nix
│   ├── git.nix
│   ├── env/         # runtime env from secrets.json
│   ├── nvim/
│   ├── shell/       # fish, yazi, starship/, fastfetch/
│   ├── herdr/       # default.nix, plus.nix, recent-navigator.nix
│   ├── agents/
│   │   ├── AGENTS.md
│   │   ├── skills/
│   │   ├── claude-code.nix
│   │   ├── hermes.nix
│   │   ├── ollama.nix
│   │   ├── notion/  # shared Notion MCP wrapper and token helper
│   │   ├── codex/
│   │   │   ├── plugins/
│   │   │   └── skills/
│   │   └── pi/
│   │       ├── activation.nix
│   │       ├── config.nix
│   │       ├── extensions.nix
│   │       ├── package.nix
│   │       └── packages/
│   ├── media/       # mpd, rmpc/
│   └── desktop/     # apps.nix, xdg.nix
└── secrets.json  # local only, ignored by git
```

## Secrets

`secrets.json` is optional, local-only, and ignored by git. The current runtime generator reads it from `/home/wanmixc/configuration/secrets.json`.

If present, it may contain:

```json
{
  "github_token": "your github token",
  "notion_token": "your Notion integration token",
  "paste_api_url": "https://your paste api domain",
  "mimo_api_key": "your Mimo API key",
  "ntfy_url": "https://ntfy.example/your-private-topic"
}
```

`github_token` is optional and enables authenticated GitHub HTTPS operations through a runtime credential helper generated under `~/.config/runtime-env/github-credential-helper`.

`notion_token` is required for machines that import `programs/agents/codex/default.nix`. Home Manager validates that it is a non-empty string before making changes, writes it at activation time to the mode-`0600` file `~/.config/runtime-env/notion-token`, and configures Codex with the managed `notion-api` MCP server. The token is not written to the Nix store or `~/.codex/config.toml`.

`paste_api_url` is optional and is written at activation time to `~/.config/runtime-env/paste.fish` as `WAN_PASTE_URL`. The `wan-copy` and `wan-paste` Fish functions require it and will print a warning if it is not configured.

`mimo_api_key` is required on machines using Pi's configured Mimo provider. It is written to `~/.config/runtime-env/mimo.fish` as `MIMO_API_KEY`, and new Fish shells source this file automatically. `pi_api_key` is also accepted as a legacy fallback when `mimo_api_key` is absent.

If the file is absent, the configuration still evaluates successfully. A Home Manager switch for a machine with Codex fails before the write boundary when `notion_token` is absent or empty.

The current runtime generator reads this file from `/home/wanmixc/configuration/secrets.json`. If the repository is cloned elsewhere, update `secretsPath` in `flake.nix` before relying on runtime credentials.

## Pi Coding Agent

`pi-coding-agent` is imported by all three host targets through `programs/agents/pi/default.nix`. Its Mimo provider uses the generated `MIMO_API_KEY` environment variable. The Pi extensions are installed declaratively from `programs/agents/pi/packages/` and their exact versions are pinned in `programs/agents/pi/config.nix`, so Pi does not perform an online package update check at startup. Update the package manifest, lockfile, and Pi version pins together when upgrading them.

### Long-task ntfy notifications

Automatic chat naming makes one best-effort attempt after the first successful interactive response. It sends one bounded user/assistant excerpt pair through the active model, uses no retries, does not backfill existing conversations, and preserves manual names. A naming failure leaves the chat unnamed and is final for that session.

The local Pi extension sends one notification when an interactive task finishes responding or ends with an agent/provider error **after more than 60 seconds**. Retries and queued follow-ups count as one busy period. Short tasks and manual cancellation stay silent; individual tool errors do not trigger alerts. Print, JSON, and RPC modes do not notify.

Add `ntfy_url` (the full HTTPS topic URL) to your local `secrets.json`, preserving its other keys. No token is used. Restrict access with `chmod 600 secrets.json`. The extension reads this file at notification time, so URL changes need no rebuild. Neither the URL nor the file contents are evaluated by Nix or copied into the Nix store. An unauthenticated topic is not private from anyone who knows its URL; use an unguessable topic and do not share it.

Edit `autoChatName.enable` and `ntfyNotifications.enable` independently in `programs/agents/pi/extensions.nix`; the extension is installed when either feature is enabled. Change `thresholdSeconds` (non-negative integer seconds) or the runtime `secretsFile` path there as well. Apply with your usual Home Manager switch (VPS: `home-manager switch --flake .#wanmixc-vps`), then restart Pi or run `/reload`. Ensure the new extension files are Git-tracked before using a Git-backed flake; Git flakes exclude untracked files.

Notifications include the server hostname, folder (`~` for your home directory), current Pi chat name, duration, and status. The title is `Pi finished — <server>` or `Pi error — <server>`. Name your chat with `/name`; unnamed chats show `Unnamed chat`, never a prompt-derived fallback. Folder paths and chat names are sent to ntfy, but prompts, code, and raw errors are not. Metadata is kept on one line per field and truncated to 240 characters per field. Delivery runs in the background with a five-second deadline, without redirects or retries. Missing/invalid configuration or failed delivery produces a generic local warning and does not fail the task. Cancelling a retry with the configured interrupt key (normally Esc) also stays silent.

Run the offline tests with:

```sh
node --test programs/agents/pi/tests/*.test.mjs
```

## Paste Commands

Fish provides paste API helpers:

```fish
wan-copy "hello from paste api"
wan-copy file.txt
wc file.txt
wan-paste aB3xZ
wan-paste aB3xZ output.txt
wp aB3xZ output.txt
wan-del-paste aB3xZ
```

`wan-copy` creates a paste and prints the returned 5-character ID. If the command receives one argument and it is a readable file, it sends that file's content. `wan-paste` fetches a paste by ID and prints its content, or writes it to the provided output file. If the output file already exists, `wan-paste` writes to the next available name such as `output-1.txt` or `output-2.txt` instead of overwriting. `wan-del-paste` deletes a paste by ID. Fish abbreviations expand `wc` to `wan-copy` and `wp` to `wan-paste` while typing.

File pastes preserve multiline content. Empty or whitespace-only files are rejected before upload, and API validation failures are printed with their HTTP status and response message.

The commands read the API base URL from `paste_api_url` in `secrets.json`:

```json
{
  "paste_api_url": "https://your paste api domain"
}
```

After changing `secrets.json`, run `home-manager switch` for the target machine and open a new Fish shell. If `paste_api_url` is missing, both commands exit with a warning instead of using a fallback URL.

## Host Module Matrix

Current machine-specific imports:

```text
common (all hosts):
  base env git fish starship devtools pi nvim herdr herdr-plus
  herdr-recent-navigator yazi fastfetch

agents:  codex claude-code
desktop: xdg desktop rmpc mpd ollama

cachyos-nix: common agents desktop
wsl:         common agents
vps:         common
```

To add a tool everywhere, import it in `profiles/common.nix`. To enable it on one machine, import it in that host file under `hosts/` or in a profile that host uses.

## Usage

Clone the repository wherever you want, for example:

```bash
git clone https://github.com/Wanmixc/home-manager-linux.git ~/.config/home-manager
cd ~/.config/home-manager
```

Apply a target with Home Manager:

```bash
home-manager switch --impure --flake .#wanmixc-cachyos-nix
home-manager switch --impure --flake .#wanmixc-wsl
home-manager switch --impure --flake .#wanmixc-vps
```

If local files already exist and need backup:

```bash
home-manager switch -b backup --impure --flake .#wanmixc-cachyos-nix
```

## Compatibility Wrapper

`home.nix` remains as a thin compatibility wrapper.

Current behavior:

- auto-selects `wsl` when WSL is detected
- auto-selects `cachyos-nix` on host `Wan-PC`
- requires explicit `--flake` selection for unsupported non-flake hosts such as VPS

For VPS, prefer:

```bash
home-manager switch --impure --flake .#wanmixc-vps
```

## Notes

- Desktop-only integrations such as Edge and Codex Chrome DevTools MCP are enabled through [programs/desktop/apps.nix](programs/desktop/apps.nix) and currently imported by `cachyos-nix`.
- Claude Code is packaged in [programs/agents/claude-code.nix](programs/agents/claude-code.nix) by overriding `pkgs.claude-code` to the pinned upstream binary version.
- Herdr itself is configured in [programs/herdr/default.nix](programs/herdr/default.nix), with raw TOML config in [programs/herdr/config.toml](programs/herdr/config.toml). Herdr and Herdr Plus are imported by all three host profiles.
- Herdr Plus is installed and registered by [programs/herdr/plus.nix](programs/herdr/plus.nix).
- Hermes Agent is available through [programs/agents/hermes.nix](programs/agents/hermes.nix), but is not currently imported by a host profile.
