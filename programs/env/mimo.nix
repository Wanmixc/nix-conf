{ pkgs, secretsPath, ... }:
{
  home.activation.mimoRuntimeEnv = ''
    runtime_env_dir="$HOME/.config/runtime-env"
    mimo_fish="$runtime_env_dir/mimo.fish"

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_env_dir"

    mimo_api_key="$(${pkgs.python3}/bin/python3 -c '
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    print("")
    raise SystemExit(0)

value = data.get("mimo_api_key", "")
if not isinstance(value, str) or value == "":
    value = data.get("pi_api_key", "")
if isinstance(value, str):
    print(value)
else:
    print("")
' ${secretsPath})"

    if [ -n "$mimo_api_key" ]; then
      ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "$mimo_api_key" <<'PY'
import pathlib
import shlex
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
key = sys.argv[2]

(runtime_env_dir / "mimo.fish").write_text(
    "set -gx MIMO_API_KEY %s\n" % shlex.quote(key),
    encoding="utf-8",
)
PY

      ${pkgs.coreutils}/bin/chmod 600 "$mimo_fish"
    else
      ${pkgs.coreutils}/bin/rm -f "$mimo_fish"
    fi
  '';
}
