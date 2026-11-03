{ pkgs, secretsPath, ... }:
{
  home.activation.githubRuntimeEnv = ''
    runtime_env_dir="$HOME/.config/runtime-env"
    github_helper="$runtime_env_dir/github-credential-helper"
    gh_fish="$runtime_env_dir/gh.fish"

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_env_dir"

    ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "${secretsPath}" <<'PY'
import pathlib
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
secrets_path = sys.argv[2]

helper_script = """\
#!/usr/bin/env bash
# BEGIN github-credential-helper
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
print(f"******")
INNER_PY
# END github-credential-helper
""".replace("__SECRETS_PATH__", secrets_path)

(runtime_env_dir / "github-credential-helper").write_text(helper_script, encoding="utf-8")
PY

    ${pkgs.coreutils}/bin/chmod 700 "$github_helper"

    ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "${secretsPath}" <<'PY'
import json
import pathlib
import shlex
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
secrets_path = sys.argv[2]
gh_fish = runtime_env_dir / "gh.fish"

github_token = ""
try:
    with open(secrets_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

value = data.get("github_token", "")
if isinstance(value, str):
    github_token = value

if github_token:
    gh_fish.write_text(
        "set -gx GH_TOKEN %s\n" % shlex.quote(github_token),
        encoding="utf-8",
    )
else:
    try:
        gh_fish.unlink()
    except FileNotFoundError:
        pass
PY

    if [ -f "$gh_fish" ]; then
      ${pkgs.coreutils}/bin/chmod 600 "$gh_fish"
    fi
  '';
}
