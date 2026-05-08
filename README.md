# Home Manager Linux

Personal [Home Manager](https://nix-community.github.io/home-manager/) configuration for Linux, managed with [Nix](https://nixos.org/).

This repository declaratively defines the user environment — installed packages, dotfiles, shell settings, and program configurations — so everything can be reproduced on any Linux machine with Nix.

> [!IMPORTANT]
> Before running `home-manager switch`, create a `secrets.json` file in the repository root:
>
> ```json
> {
>   "github_token": "your github token"
> }
> ```

## What's Included

| Category | Details |
|---|---|
| **Editor** | Neovim (custom `nvim/init.lua`), Vim |
| **Shell & Terminal** | Fish (custom `fish.config`), Tmux, Starship prompt, Zoxide, Direnv, Bash Language Server, ShFmt |
| **Music** | MPD user service + `rmpc` terminal client (`rmpc/config.ron`) |
| **File Manager** | Yazi (with Neovim integration and Fish shell support) |
| **Git** | Git with [delta](https://github.com/dandavison/delta) (side-by-side diffs), GitUI |
| **Search & Utilities** | Ripgrep, Bat, Eza, Unzip, Fastfetch (custom config + logo) |
| **AI Tools** | [Codex CLI](https://github.com/openai/codex) |
| **Browser** | Microsoft Edge |
| **Runtime** | Bun |

## Repository Structure

```text
.
├── home.nix              # Main Home Manager configuration and module imports
├── fish.config           # Fish shell custom configuration
├── fastfetch/
│   ├── config.jsonc      # Fastfetch system info display config
│   └── logo.txt          # Fastfetch custom logo
├── nvim/
│   └── init.lua          # Neovim configuration
├── rmpc/
│   └── config.ron        # rmpc layout, keybinds, and MPD client config
├── starship/
│   └── ...               # Starship prompt configuration
├── codex/
│   └── skills/           # Codex skills managed by Home Manager
├── tmux/
│   └── tmux.nix          # Tmux Home Manager module
├── secrets.json          # (git-ignored) GitHub token
└── README.md
```

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/download/) package manager
- [Home Manager](https://nix-community.github.io/home-manager/) installed as a standalone tool or NixOS module

### Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/Wanmixc/home-manager-linux.git ~/.config/home-manager
   ```

2. Create a `secrets.json` file in the repository root with your tokens:

   ```json
   {
     "github_token": "your github token"
   }
   ```

3. Apply the configuration:

   ```bash
   home-manager switch
   ```

## Key Configuration Highlights

- **Git** — Configured with `delta` for side-by-side diffs, automatic remote setup on push, and private repo access via tokens from `secrets.json`.
- **Yazi** — Opens text files in Neovim by default; hidden files are shown.
- **Direnv** — Enabled for per-directory environment management.
- **rmpc + MPD** — MPD runs as a Home Manager user service with socket activation, and `rmpc` is configured from `rmpc/config.ron` with a custom multi-pane layout.
- **Tmux** — Modularized into `tmux/tmux.nix` with quick split bindings, `Alt-h/j/k/l` pane navigation, and a status bar styled to match the local terminal palette.
- **Fish** — Custom shell configuration in `fish.config` with aliases, Starship prompt integration, Zoxide, Direnv, and fastfetch on startup.
- **Starship** — Minimal prompt configuration with custom styling.
- **Codex CLI** — Packaged as a custom Nix overlay fetched from the official GitHub release.
- **Codex Skills** — Installs the `commit-message-id` skill into `~/.codex/skills` via Home Manager activation so Codex can use the Indonesian commit message guideline.
