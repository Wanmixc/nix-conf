{ pkgs, secretsPath, ... }:
{
  home.activation.pasteRuntimeEnv = ''
    runtime_env_dir="$HOME/.config/runtime-env"
    paste_fish="$runtime_env_dir/paste.fish"

    ${pkgs.coreutils}/bin/mkdir -p "$runtime_env_dir"

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
  '';
}
