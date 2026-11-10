{ lib, fetchurl, runCommand, jq, python3, buildNpmPackage, makeBinaryWrapper, ripgrep, fd }:

let
  version = "1.5.0";

  rawSrc = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    sha256 = "5bfb66848a4c4b81c637ce8d2136be01945b70aac8e8556b091cb02241b385df";
  };

  # Since 1.0.0 the published tarball ships no lockfile. Generate one with
  # `npm install --package-lock-only` (see the header comment below), vendor it
  # in this directory, and have the sandboxed build step only patch it in.
  #
  # Update procedure for a new version:
  #   1. set `version` and refresh `rawSrc.hash`
  #   2. regenerate the vendored lockfile:
  #        npm install --package-lock-only --ignore-scripts --omit=dev \
  #          --prefix <unpacked tarball with devDependencies removed>
  #      and copy it to pi-coding-agent-<version>-package-lock.json
  #   3. set `npmDepsHash` to a dummy, build, and use the reported hash
  vendoredLockfile = ./pi-coding-agent-${version}-package-lock.json;

  src = runCommand "pi-coding-agent-src-${version}" {
    nativeBuildInputs = [ jq python3 ];
  } ''
    mkdir -p "$out"
    tar xzf ${rawSrc} --strip-components=1 -C "$out"
    chmod -R u+w "$out"
    cd "$out"

    # devDependencies are published workspace members and rely on local
    # workspaces, so drop them and install the release dependencies only.
    jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
    cp ${vendoredLockfile} package-lock.json

    # The published tarball ships a prebuilt bundle, and the `pi` binary is
    # dist/bundle/cli.js. Only that bundle runs, so every rewrite must target
    # dist/bundle/chunks/*.js; the unbundled dist/modes/** tree is dead code
    # for the CLI. Keep modifiers exact so a Pi upgrade fails loudly instead
    # of silently losing behavior.
    ${python3}/bin/python3 - <<'PY'
from pathlib import Path
import glob

# --- dist/bundle/chunks: the code the `pi` binary actually executes ---
skill_push_old = 'skillCommandList.push({name:commandName,description:this.prefixAutocompleteDescription(skill.description,skill.sourceInfo)})'
skill_push_new = 'skillCommandList.push({name:commandName,description:this.prefixAutocompleteDescription(skill.description,skill.sourceInfo),argumentHint:"<request>"})'

# Enter on an open slash-command menu must fill the editor, not submit, so
# arguments can be appended before the next Enter sends the prompt.
confirm_old = 'this.autocompletePrefix.startsWith("/"))this.cancelAutocomplete();else{this.cancelAutocomplete(),this.onChange&&this.onChange(this.getText());return}}}}'
confirm_new = 'this.autocompletePrefix.startsWith("/")){this.cancelAutocomplete();return}else{this.cancelAutocomplete(),this.onChange&&this.onChange(this.getText());return}}}}'

bundle_edits = [
    ("skillCommandList.push", skill_push_old, skill_push_new),
    ("slash confirm", confirm_old, confirm_new),
]

hits = {label: [] for label, _, _ in bundle_edits}
for chunk in sorted(glob.glob("dist/bundle/chunks/*.js")):
    text = Path(chunk).read_text()
    original = text
    for label, old, new in bundle_edits:
        if old in text:
            hits[label].append(chunk)
            text = text.replace(old, new)
    if text != original:
        Path(chunk).write_text(text)

for label, _, _ in bundle_edits:
    if len(hits[label]) != 1:
        raise SystemExit(f"expected exactly one bundle target for {label}, found {hits[label]}")
PY
  '';
in
buildNpmPackage {
  pname = "pi-coding-agent";
  inherit version src;

  npmDepsHash = "sha256-vS2bvmISxWo3HmHct7FT07Nc9CGO38g+hDRwqWw8Auo=";

  # The published tarball already ships a built dist/, so there is nothing
  # to compile; only install the pinned dependencies.
  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" "--omit=dev" ];

  # pi-tui is bundled into dist/bundle/chunks at publish time, so the
  # installed node_modules/@earendil-works/pi-tui copy is never loaded by the
  # `pi` binary. Enter handling is patched in the bundle above instead.

  nativeBuildInputs = [ makeBinaryWrapper python3 ];

  # pi shells out to ripgrep and fd at runtime.
  postFixup = ''
    wrapProgram "$out/bin/pi" \
      --prefix PATH : ${lib.makeBinPath [ ripgrep fd ]}
  '';

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
