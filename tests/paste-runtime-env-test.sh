#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/programs/env.nix"
fish_file="$repo_root/programs/fish.nix"
devtools_file="$repo_root/programs/devtools.nix"

if ! grep -Fq 'paste_api_url' "$env_file"; then
  echo "expected programs/env.nix to read paste_api_url from secrets.json" >&2
  exit 1
fi

if ! grep -Fq 'paste.fish' "$env_file"; then
  echo "expected programs/env.nix to generate paste.fish runtime env" >&2
  exit 1
fi

if ! grep -Fq 'WAN_PASTE_URL' "$fish_file"; then
  echo "expected programs/fish.nix to require WAN_PASTE_URL" >&2
  exit 1
fi

if ! grep -Fq 'wan-copy' "$fish_file"; then
  echo "expected programs/fish.nix to define wan-copy" >&2
  exit 1
fi

if ! grep -Fq 'wan-paste' "$fish_file"; then
  echo "expected programs/fish.nix to define wan-paste" >&2
  exit 1
fi

if ! grep -Fq 'jq' "$devtools_file"; then
  echo "expected programs/devtools.nix to install jq" >&2
  exit 1
fi

echo "ok"
