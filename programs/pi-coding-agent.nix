{ pkgs, lib, ... }:
let
  version = "0.80.3";

  # Custom OpenAI-compatible provider written to ~/.pi/agent/models.json on
  # activation. The API key is read from the gitignored secrets.json (under
  # `pi_api_key`) so it never lands in the Nix store or git.
  secretsPath = "/home/wanmixc/configuration/secrets.json";
  provider = {
    name = "mimo";
    baseUrl = "https://mimo.lokerin.net/v1";
    api = "openai-completions";
    modelId = "cutad-agent-pro";
    modelName = "Cutad Agent Pro";
  };

  # sha512 SRI integrity for the three @earendil-works workspace tarballs.
  # The published npm-shrinkwrap.json omits these, which breaks `npm ci`
  # under Nix. Values come from `npm view @earendil-works/<pkg>@<version>
  # dist.integrity` and must be refreshed together with `version`.
  workspaceIntegrity = {
    pi-ai = "sha512-jPZLMeGL5kkMSEAwAklfXTMHqZvfhsJtCCpKGIr5Duk7mc0n4skjB1dugk7y0z3z8ZHIUCmPAWHdyDqgUz5vdA==";
    pi-agent-core = "sha512-3qw0/GeRQBU/nlGjDe5Yb7ePKTmoxefx2YxyKMFAviFUMXpFexBG/hS7mBtwFahFvzrrTPPoRT6sFIDjwoDWPQ==";
    pi-tui = "sha512-2BJI6qwRQfnM0Q7seL1+SbacU/jRRjBnN7Hu3n9BjAn7/s5FaBNnvdD1qBQYRsFTHfjqMaDsjYqanPyqwXj99w==";
  };

  rawSrc = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-FVxYABNMuN9sR62z6rVkFej6d0bgscumaHE0E3xFHZA=";
  };

  # Unpack the npm tarball, backfill the missing workspace integrities so both
  # dependency fetching and `npm ci` see a valid lockfile, and drop the
  # devDependencies (which the published shrinkwrap omits) since dist/ is
  # already built and we never compile.
  src = pkgs.runCommand "pi-coding-agent-src-${version}" {
    nativeBuildInputs = [ pkgs.jq ];
  } ''
    mkdir -p "$out"
    tar xzf ${rawSrc} --strip-components=1 -C "$out"
    cd "$out"
    jq '
        .packages["node_modules/@earendil-works/pi-ai"].integrity = "${workspaceIntegrity.pi-ai}"
      | .packages["node_modules/@earendil-works/pi-agent-core"].integrity = "${workspaceIntegrity.pi-agent-core}"
      | .packages["node_modules/@earendil-works/pi-tui"].integrity = "${workspaceIntegrity.pi-tui}"
    ' npm-shrinkwrap.json > npm-shrinkwrap.json.tmp
    mv npm-shrinkwrap.json.tmp npm-shrinkwrap.json
    jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version src;

    npmDepsHash = "sha256-lO8UJ4qf9LXWaC4DChhwS1dzYndf8JYphGvdRqbtpKM=";

    # The published tarball already ships a built dist/, so there is nothing
    # to compile; only install the pinned dependencies.
    dontNpmBuild = true;
    npmFlags = [ "--ignore-scripts" "--omit=dev" ];

    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

    # pi shells out to ripgrep and fd at runtime.
    postFixup = ''
      wrapProgram "$out/bin/pi" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';

    meta = {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://pi.dev/";
      license = lib.licenses.mit;
      mainProgram = "pi";
    };
  };
in
{
  home.packages = [ pi-coding-agent ];

  # Render ~/.pi/agent/models.json from secrets.json on every activation.
  # Only models.json is written; auth.json (OAuth from `/login`) is left alone.
  home.activation.piCodingAgentConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    pi_agent_dir="$HOME/.pi/agent"
    ${pkgs.coreutils}/bin/mkdir -p "$pi_agent_dir"

    ${pkgs.python3}/bin/python3 - "${secretsPath}" "$pi_agent_dir/models.json" <<'PY'
import json, os, sys

secrets_path, models_path = sys.argv[1], sys.argv[2]

try:
    with open(secrets_path, encoding="utf-8") as f:
        secrets = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    secrets = {}

api_key = secrets.get("pi_api_key", "")

provider = {
    "baseUrl": "${provider.baseUrl}",
    "api": "${provider.api}",
    "models": [
        {"id": "${provider.modelId}", "name": "${provider.modelName}", "input": ["text"]}
    ],
}
if isinstance(api_key, str) and api_key:
    provider["apiKey"] = api_key

with open(models_path, "w", encoding="utf-8") as f:
    json.dump({"providers": {"${provider.name}": provider}}, f, indent=2)
    f.write("\n")

# The file embeds the API key, so keep it owner-only.
os.chmod(models_path, 0o600)
PY
  '';
}
