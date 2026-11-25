{ pkgs, secretsPath, ... }:
{
  home.activation.tokenharborRuntimeEnv = ''
    runtime_env_dir="$HOME/.config/runtime-env"
    ${pkgs.coreutils}/bin/mkdir -p "$runtime_env_dir"

    ${pkgs.python3}/bin/python3 - "$runtime_env_dir" "${secretsPath}" <<'PY'
import json
import os
import pathlib
import shlex
import sys

runtime_env_dir = pathlib.Path(sys.argv[1])
env_path = runtime_env_dir / "tokenharbor.fish"

try:
    with open(sys.argv[2], "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    data = {}

key = data.get("tokenharbor_api_key", "")
if not isinstance(key, str) or not key:
    env_path.unlink(missing_ok=True)
else:
    fd = os.open(env_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write("set -gx TOKENHARBOR_API_KEY %s\n" % shlex.quote(key))
    os.chmod(env_path, 0o600)
PY
  '';
}
