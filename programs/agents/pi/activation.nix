{ pkgs, lib, secretsPath, ... }:
{
  # Keep asynchronous startup update banners out of normal interactive use.
  # Explicit update commands still run normally: `pi update` and
  # `pi update --extensions`.
  programs.fish.functions.pi = {
    body = ''
      if test (count $argv) -eq 0
        env PI_SKIP_VERSION_CHECK=1 /home/wanmixc/.local/state/nix/profiles/profile/bin/pi
      else
        command pi $argv
      end
    '';
  };

  home.activation.piPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    package_source=${./packages}
    target="$HOME/.pi/agent/npm"
    mkdir -p "$target"
    # Files copied from the Nix store are read-only. Replace old manifests
    # atomically so repeated Home Manager switches do not fail on permissions.
    cp "$package_source/package.json" "$target/.package.json.tmp"
    cp "$package_source/package-lock.json" "$target/.package-lock.json.tmp"
    mv -f "$target/.package.json.tmp" "$target/package.json"
    mv -f "$target/.package-lock.json.tmp" "$target/package-lock.json"
    ${pkgs.nodejs}/bin/npm ci --ignore-scripts --omit=dev --prefix "$target"

    # Pi aliases host-provided packages (typebox, @earendil-works/*) to its own
    # copies when loading extensions, so copies installed under $target are
    # never imported. pi-web-access still lists typebox under dependencies,
    # which Pi reports at startup as a package that could bypass the extension
    # loader. Move it to peerDependencies to match Pi's expectation.
    ${pkgs.python3}/bin/python3 ${./packages/fix-host-deps.py} "$target/node_modules"
    # Tell Herdr while a pi-permission-system dialog is awaiting input.
    ${pkgs.python3}/bin/python3 ${./packages/fix-permission-herdr.py} "$target/node_modules"
  '';

  home.activation.validatePiNotionToken = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${../notion/notion_token.py} check ${secretsPath}
  '';

  home.activation.piNotion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${../notion/notion_token.py} write ${secretsPath} "$HOME/.config/runtime-env/notion-token"
  '';
}
