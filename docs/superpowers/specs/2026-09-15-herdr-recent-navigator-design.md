# Herdr Recent Navigator declarative installation

## Goal

Install `beyondlex/herdr-recent-navigator` through the existing Nix/Home
Manager configuration so the plugin binary, Herdr registration, and keybinding
are reproducible and survive Home Manager activation.

## Design

- Add a dedicated `programs/herdr-recent-navigator.nix` module following the
  existing `programs/herdr-plus.nix` registration pattern.
- Build a pinned upstream Rust source with `rustPlatform.buildRustPackage`.
- Install the upstream manifest beside the built binary, rewriting commands
  from the source-tree path to the Nix-store-relative `./bin/herdr-recent-navigator`
  path expected by Herdr.
- Register the manifest as the local plugin
  `beyondlex.herdr-recent-navigator` during Home Manager activation while
  preserving unrelated Herdr plugins.
- Import the module in the CachyOS, WSL, and VPS host profiles, matching the
  current Herdr Plus availability.
- Add one Herdr binding in `programs/herdr/config.toml`:

  - `prefix+f` -> `beyondlex.herdr-recent-navigator.open`

- Do not add bindings for previous-tab or previous-pane actions.

## Verification

- Evaluate/build the affected Home Manager configurations.
- Check the generated plugin manifest and registry entry.
- Confirm the Herdr config parses and contains only the requested binding.
- Check the final diff for unrelated changes.
