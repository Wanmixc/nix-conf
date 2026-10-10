# Repository instructions

Global rules for all agents live in `programs/agents/AGENTS.md`. This file only
covers working on this repository.

## Scope

This repository is the source of truth for the Home Manager configuration of
Codex, Claude Code, and Pi agent, including their shared instructions and
skills.

## Layout

- `programs/agents/AGENTS.md`: global instructions, deployed to
  `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`, and `~/.pi/agent/AGENTS.md`.
- `programs/agents/skills/<name>/SKILL.md`: shared skills for all agents.
- `programs/agents/skills/superpowers/`: vendored copy of the Claude Code
  superpowers plugin skills for Codex and Pi (Claude uses the plugin itself).
  Refresh after plugin updates with
  `rsync -a --delete --chmod=u+w ~/.claude/plugins/cache/claude-plugins-official/superpowers/<version>/skills/ programs/agents/skills/superpowers/`.
  Currently 6.4.1.
- `programs/codex/skills/`: Codex-only skills.
- `secrets.json`: local secrets, gitignored. Never commit it.

## Rules

- Put reusable workflows in `programs/agents/skills/<name>/SKILL.md` and wire
  them in the tool modules.
- Do not assume files in `docs/` are loaded automatically. Read `SPEC.md` for
  product requirements, boundaries, and acceptance criteria when it exists.
- Flakes only see git-tracked files: `git add -N` new files before `nix eval`
  or `nix build`.
- Verify changes by evaluating every affected host in `flake.nix`
  (`homeConfigurations.wanmixc-<host>.activationPackage`).

## Maintenance

- Keep instruction files short enough to follow. Add rules only when they
  prevent a real repeat mistake or document durable behavior.
- When the user corrects an approach, tighten the relevant rule instead of
  appending a vague warning.
