{ pkgs, lib, ... }:
let
  version = "1.1.0";

  rawSrc = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-Cc2KCkPbsdgaZzRrCUALQ5znHYGMq6TpY+qViEahrtQ=";
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

  src = pkgs.runCommand "pi-coding-agent-src-${version}" {
    nativeBuildInputs = [ pkgs.jq pkgs.python3 ];
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

    # Make Tab context-aware: autocomplete wins when visible; otherwise Tab
    # queues a follow-up only while the agent is working. Keep these rewrites
    # exact so a Pi upgrade fails loudly instead of silently losing behavior.
    ${pkgs.python3}/bin/python3 - <<'PY'
from pathlib import Path

replacements = {
    Path("dist/modes/interactive/components/custom-editor.js"): (
        """        // Check all other app actions
""",
        """        // Let autocomplete consume Tab before the follow-up action.
        if (this.keybindings.matches(data, \"app.message.followUp\") && this.isShowingAutocomplete()) {
            super.handleInput(data);
            return;
        }
        // Check all other app actions
""",
    ),
    Path("dist/modes/interactive/interactive-mode.js"): (
        """        // If not streaming, Alt+Enter acts like regular Enter (trigger onSubmit)
        else if (this.editor.onSubmit) {
            this.editor.setText(\"\");
            this.editor.onSubmit(text);
        }
""",
        """        // Follow-up is only meaningful while the agent is working.
        // When idle, Tab remains available for autocomplete and never submits.
""",
    ),
}

for path, (old, new) in replacements.items():
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"patch target not found: {path}")
    path.write_text(text.replace(old, new, 1))
PY
  '';

  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version src;

    npmDepsHash = "sha256-dB8OUdcpBrQKBy1jhIkXwjfWiAqDmjW5s2LO42UyYHo=";

    # The published tarball already ships a built dist/, so there is nothing
    # to compile; only install the pinned dependencies.
    dontNpmBuild = true;
    npmFlags = [ "--ignore-scripts" "--omit=dev" ];

    # pi-tui is a dependency installed by npm rather than part of src. Patch
    # its Enter completion path after installation so slash/file completion
    # never submits the prompt accidentally.
    postInstall = ''
      found=0
      while IFS= read -r editor; do
        ${pkgs.python3}/bin/python3 - "$editor" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
confirm = '            if (kb.matches(data, "tui.select.confirm")) {'
confirm_pos = text.find(confirm)
if confirm_pos < 0:
    raise SystemExit(f"confirm target not found: {path}")
selected = '                const selected = this.autocompleteList.getSelectedItem();\n'
selected_pos = text.find(selected, confirm_pos)
provider = '                if (selected && this.autocompleteProvider) {\n'
provider_pos = text.find(provider, selected_pos)
if selected_pos < 0 or provider_pos < 0:
    raise SystemExit(f"confirm selection target not found: {path}")
insert_at = provider_pos + len(provider)
text = text[:insert_at] + """                    const wasExactSlashCommand = this.autocompletePrefix.startsWith(\"/\") &&
                        this.getText().trim() === `/''${selected.value}`;
                    const slashPrefix = this.autocompletePrefix.startsWith(\"/\")
                        ? this.autocompletePrefix.slice(1).toLowerCase()
                        : \"\";
                    const matchingSlashCommands = slashPrefix
                        ? this.autocompleteList.filteredItems.filter((item) => item.value.toLowerCase().startsWith(slashPrefix))
                        : [];
                    const isOnlyMatchingSlashCommand = matchingSlashCommands.length === 1 &&
                        matchingSlashCommands[0].value === selected.value;
""" + text[insert_at:]
slash = 'if (this.autocompletePrefix.startsWith("/")'
slash_pos = text.find(slash, confirm_pos)
if slash_pos < 0:
    raise SystemExit(f"slash condition target not found: {path}")
comment = '                        // Fall through to submit'
comment_pos = text.find(comment, slash_pos)
if comment_pos < 0:
    raise SystemExit(f"slash submit marker not found: {path}")
text = text[:comment_pos] + '                        if (!wasExactSlashCommand && !isOnlyMatchingSlashCommand)\n                            return;' + text[comment_pos + len(comment):]
path.write_text(text)
PY
        found=$((found + 1))
      done < <(find "$out" -path '*/node_modules/@earendil-works/pi-tui/dist/components/editor.js' -type f)
      test "$found" -eq 1
    '';

    nativeBuildInputs = [ pkgs.makeBinaryWrapper pkgs.python3 ];

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
}
