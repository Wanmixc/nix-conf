{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    microsoft-edge
    mpv
    sxiv
  ];

  xdg.configFile."mpv/mpv.conf".text = ''
    keep-open=yes
    vo=wlshm
    ytdl-format=bestvideo[height<=720]+bestaudio/best[height<=720]
  '';

  home.activation.codexChromeDevtoolsMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CODEx_CONFIG="$HOME/.codex/config.toml"
    mkdir -p "$HOME/.codex"

    if [ -f "$CODEx_CONFIG" ]; then
      if grep -q '^\[mcp_servers\.chrome-devtools\]$' "$CODEx_CONFIG"; then
        ${pkgs.gawk}/bin/awk '
          BEGIN { skip = 0 }
          /^\[mcp_servers\.chrome-devtools\]$/ { skip = 1; next }
          /^\[/ && skip { skip = 0 }
          !skip { print }
        ' "$CODEx_CONFIG" > "$CODEx_CONFIG.tmp"
        mv "$CODEx_CONFIG.tmp" "$CODEx_CONFIG"
      fi
    fi

    cat >> "$CODEx_CONFIG" <<'EOF'

[mcp_servers.chrome-devtools]
command = "bunx"
args = [
  "chrome-devtools-mcp@latest",
  "--executablePath",
  "${pkgs.microsoft-edge}/bin/microsoft-edge",
]
EOF
  '';
}
