# Home Manager

Personal multi-machine [Home Manager](https://nix-community.github.io/home-manager/) configuration for:

- `cachyos-nix`
- `wsl`
- `vps`

This repository uses a mostly flat `programs/` layout: each app or concern has a small `.nix` module, with larger tools keeping their supporting config in a matching subdirectory.

## Host Targets

Available Home Manager flake targets:

- `wanmixc-cachyos-nix`
- `wanmixc-wsl`
- `wanmixc-vps`

## Rules

AI tool policy:

- `cachyos-nix` -> `codex`, `claude-code`
- `wsl` -> `codex`, `claude-code`, `pi-coding-agent`, `hermes`
- `vps` -> `deepseek`
- Claude Code is split into `programs/claude-code.nix` so it can be imported only on selected machines.

Neovim policy:

- one shared Neovim config
- source of truth is the `programs/nvim/` folder in this repo

## Repository Structure

```text
.
├── flake.nix
├── home.nix
├── hosts/
│   ├── cachyos-nix.nix
│   ├── wsl.nix
│   └── vps.nix
├── programs/
│   ├── base.nix
│   ├── env.nix
│   ├── git.nix
│   ├── fish.nix
│   ├── starship.nix
│   ├── xdg.nix
│   ├── devtools.nix
│   ├── desktop.nix
│   ├── claude-code.nix
│   ├── codex.nix
│   ├── deepseek.nix
│   ├── hermes.nix
│   ├── pi-coding-agent.nix
│   ├── herdr-plus.nix
│   ├── nvim.nix
│   ├── tmux.nix
│   ├── yazi.nix
│   ├── fastfetch.nix
│   ├── rmpc.nix
│   ├── mpd.nix
│   ├── herdr/
│   ├── nvim/
│   ├── starship/
│   ├── tmux/
│   ├── fastfetch/
│   ├── rmpc/
│   ├── codex/
│   └── deepseek/
└── secrets.json
```

## Secrets

`secrets.json` is optional.

If present, it may contain:

```json
{
  "github_token": "your github token",
  "paste_api_url": "https://your paste api domain",
  "supermemory_codex_api_key": "your supermemory api key"
}
```

`github_token` is optional and enables authenticated GitHub HTTPS operations through a runtime credential helper generated under `~/.config/runtime-env/github-credential-helper`.

`paste_api_url` is optional and is written at activation time to `~/.config/runtime-env/paste.fish` as `WAN_PASTE_URL`. The `wan-copy` and `wan-paste` Fish functions require it and will print a warning if it is not configured.

`supermemory_codex_api_key` is optional and is written at activation time into runtime-only env files under `~/.config/runtime-env/`. Fish sources `supermemory.fish`; tmux also receives the variable when a tmux server is already running. This keeps the secret out of the Nix store.

If the file is absent, the configuration still evaluates successfully.

## Paste Commands

Fish provides two paste API helpers:

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
cachyos-nix:
  base env git fish starship xdg devtools codex desktop nvim herdr
  herdr-plus yazi fastfetch rmpc mpd claude-code

wsl:
  base env git fish starship devtools claude-code pi-coding-agent hermes
  codex nvim herdr herdr-plus yazi fastfetch

vps:
  base env git fish starship xdg devtools deepseek nvim tmux yazi fastfetch
```

To enable or disable a tool per machine, add or remove its module in the target file under `hosts/`.

## Usage

Clone the repository wherever you want, for example:

```bash
git clone https://github.com/Wanmixc/home-manager-linux.git ~/.config/home-manager
cd ~/.config/home-manager
```

Apply a target with Home Manager:

```bash
home-manager switch --flake .#wanmixc-cachyos-nix
home-manager switch --flake .#wanmixc-wsl
home-manager switch --flake .#wanmixc-vps
```

If local files already exist and need backup:

```bash
home-manager switch -b backup --flake .#wanmixc-cachyos-nix
```

## Compatibility Wrapper

`home.nix` remains as a thin compatibility wrapper.

Current behavior:

- auto-selects `wsl` when WSL is detected
- auto-selects `cachyos-nix` on host `Wan-PC`
- requires explicit `--flake` selection for unsupported non-flake hosts such as VPS

For VPS, prefer:

```bash
home-manager switch --flake .#wanmixc-vps
```

## Notes

- `programs/tmux/tmux.nix` is preserved and imported through [programs/tmux.nix](programs/tmux.nix). It is currently imported by the VPS profile.
- Desktop-only integrations such as Edge and Codex Chrome DevTools MCP are enabled through [programs/desktop.nix](programs/desktop.nix) and currently imported by `cachyos-nix`.
- DeepSeek is packaged through a binary release flow in [programs/deepseek.nix](programs/deepseek.nix) and currently imported by `vps`.
- Claude Code is packaged in [programs/claude-code.nix](programs/claude-code.nix) by overriding `pkgs.claude-code` to the pinned upstream binary version.
- Herdr itself is configured in [programs/herdr/default.nix](programs/herdr/default.nix), with raw TOML config in [programs/herdr/config.toml](programs/herdr/config.toml). Herdr Plus is installed and registered by [programs/herdr-plus.nix](programs/herdr-plus.nix).
- Hermes Agent is imported from its upstream flake by [programs/hermes.nix](programs/hermes.nix).
