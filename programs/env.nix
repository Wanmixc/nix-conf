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
    github_helper="$runtime_env_dir/github-credential-helper"
    paste_fish="$runtime_env_dir/paste.fish"
    supermemory_sh="$runtime_env_dir/supermemory.sh"
    supermemory_fish="$runtime_env_dir/supermemory.fish"
    supermemory_env="$runtime_env_dir/supermemory.env"

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_env_dir"

    ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "${secretsPath}" <<'PY'
import pathlib
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
secrets_path = sys.argv[2]

helper_script = """\
# BEGIN github-credential-helper
#!/usr/bin/env bash
set -euo pipefail

secrets_path="''${GITHUB_SECRETS_PATH:-__SECRETS_PATH__}"

request="$(${pkgs.coreutils}/bin/cat)"

${pkgs.python3}/bin/python3 - "$secrets_path" "$request" <<'INNER_PY'
import json
import sys

secrets_path = sys.argv[1]
request = sys.argv[2]

fields = {}
for line in request.splitlines():
    if "=" not in line:
        continue
    key, value = line.split("=", 1)
    fields[key] = value

if fields.get("protocol") != "https" or fields.get("host") != "github.com":
    raise SystemExit(0)

try:
    with open(secrets_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    raise SystemExit(0)
except json.JSONDecodeError:
    raise SystemExit(0)

token = data.get("github_token", "")
if not isinstance(token, str) or token == "":
    raise SystemExit(0)

print("username=oauth2")
print(f"password={token}")
INNER_PY
# END github-credential-helper
""".replace("__SECRETS_PATH__", secrets_path)

(runtime_env_dir / "github-credential-helper").write_text(helper_script, encoding="utf-8")
PY

    ${pkgs.coreutils}/bin/chmod 700 "$github_helper"

    paste_api_url="$(${pkgs.python3}/bin/python3 -c '
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    print("")
    raise SystemExit(0)

value = data.get("paste_api_url", "")
if isinstance(value, str):
    print(value)
else:
    print("")
' ${secretsPath})"

    if [ -n "$paste_api_url" ]; then
      ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "$paste_api_url" <<'PY'
import pathlib
import shlex
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
url = sys.argv[2]

(runtime_env_dir / "paste.fish").write_text(
    "set -gx WAN_PASTE_URL %s\n" % shlex.quote(url),
    encoding="utf-8",
)
PY

      ${pkgs.coreutils}/bin/chmod 600 "$paste_fish"
    else
      ${pkgs.coreutils}/bin/rm -f "$paste_fish"
    fi

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

      if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
        tmux set-environment -g SUPERMEMORY_CODEX_API_KEY "$supermemory_codex_api_key"
      fi
    else
      ${pkgs.coreutils}/bin/rm -f \
        "$supermemory_sh" \
        "$supermemory_fish" \
        "$supermemory_env"

      if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
        tmux set-environment -gu SUPERMEMORY_CODEX_API_KEY || true
      fi
    fi
  '';

  programs.fish.shellInit = ''
    if test -f "$HOME/.config/runtime-env/paste.fish"
      source "$HOME/.config/runtime-env/paste.fish"
    end

    if test -f "$HOME/.config/runtime-env/supermemory.fish"
      source "$HOME/.config/runtime-env/supermemory.fish"
    end
  '';
}
