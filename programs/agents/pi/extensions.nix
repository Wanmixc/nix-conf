{ pkgs, lib, secretsPath, ... }:
let
  autoChatName = {
    enable = true;
  };
  # Only non-secret values belong here. The extension reads ntfy_url at runtime.
  ntfyNotifications = {
    enable = true;
    thresholdSeconds = 60;
    secretsFile = secretsPath;
  };
  ntfyConfig = pkgs.writeText "pi-ntfy-config.json" (builtins.toJSON {
    autoNameEnabled = autoChatName.enable;
    notificationsEnabled = ntfyNotifications.enable;
    inherit (ntfyNotifications) thresholdSeconds secretsFile;
  });
  # Keep config and imports adjacent even after Nix/Home Manager symlink resolution.
  ntfyExtension = pkgs.runCommand "pi-ntfy-extension" { } ''
    mkdir -p "$out"
    cp ${./extensions/ntfy}/index.ts "$out/index.ts"
    cp ${./extensions/ntfy}/notify.mjs "$out/notify.mjs"
    cp ${./extensions/ntfy}/auto-name.mjs "$out/auto-name.mjs"
    cp ${./extensions/ntfy}/title-request.mjs "$out/title-request.mjs"
    cp ${ntfyConfig} "$out/config.json"
  '';

  # Vendored from `herdr integration install pi`. Reports agent state to Herdr
  # directly instead of relying on Herdr's screen-scraping detection, which
  # misreads pi as idle while it is working.
  herdrExtension = pkgs.runCommand "pi-herdr-extension" { } ''
    mkdir -p "$out"
    cp ${./extensions/herdr}/herdr-agent-state.ts "$out/herdr-agent-state.ts"
  '';
in
{
  assertions = [
    {
      assertion = builtins.isInt ntfyNotifications.thresholdSeconds && ntfyNotifications.thresholdSeconds >= 0;
      message = "Pi ntfy thresholdSeconds must be a non-negative integer.";
    }
  ];
  home.file.".pi/agent/extensions/ntfy" = lib.mkIf (autoChatName.enable || ntfyNotifications.enable) {
    source = ntfyExtension;
  };
  home.file.".pi/agent/extensions/herdr-agent-state.ts".source = "${herdrExtension}/herdr-agent-state.ts";
}
