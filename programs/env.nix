{ pkgs, ... }:
let
  secretsPath = "/home/wanmixc/configuration/secrets.json";
in
{
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.activation.supermemoryRuntimeEnv = ''
    runtime_env_dir="$HOME/.config/runtime-env"
    supermemory_sh="$runtime_env_dir/supermemory.sh"
    supermemory_fish="$runtime_env_dir/supermemory.fish"
    supermemory_env="$runtime_env_dir/supermemory.env"

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_env_dir"

    supermemory_codex_api_key="$(${pkgs.python3}/bin/python3 -c '
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    print("")
    raise SystemExit(0)

value = data.get("supermemory_codex_api_key", "")
if isinstance(value, str):
    print(value)
else:
    print("")
' ${secretsPath})"

    if [ -n "$supermemory_codex_api_key" ]; then
      ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "$supermemory_codex_api_key" <<'PY'
import pathlib
import shlex
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
key = sys.argv[2]

(runtime_env_dir / "supermemory.sh").write_text(
    "export SUPERMEMORY_CODEX_API_KEY=%s\n" % shlex.quote(key),
    encoding="utf-8",
)
(runtime_env_dir / "supermemory.fish").write_text(
    "set -gx SUPERMEMORY_CODEX_API_KEY %s\n" % shlex.quote(key),
    encoding="utf-8",
)
(runtime_env_dir / "supermemory.env").write_text(
    "SUPERMEMORY_CODEX_API_KEY=%s\n" % key.replace("\n", ""),
    encoding="utf-8",
)
PY

      ${pkgs.coreutils}/bin/chmod 600 \
        "$supermemory_sh" \
        "$supermemory_fish" \
        "$supermemory_env"

      if ${pkgs.tmux}/bin/tmux ls >/dev/null 2>&1; then
        ${pkgs.tmux}/bin/tmux set-environment -g SUPERMEMORY_CODEX_API_KEY "$supermemory_codex_api_key"
      fi
    else
      ${pkgs.coreutils}/bin/rm -f \
        "$supermemory_sh" \
        "$supermemory_fish" \
        "$supermemory_env"

      if ${pkgs.tmux}/bin/tmux ls >/dev/null 2>&1; then
        ${pkgs.tmux}/bin/tmux set-environment -gu SUPERMEMORY_CODEX_API_KEY || true
      fi
    fi
  '';

  programs.fish.shellInit = ''
    if test -f "$HOME/.config/runtime-env/supermemory.fish"
      source "$HOME/.config/runtime-env/supermemory.fish"
    end
  '';
}
