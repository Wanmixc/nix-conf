final: prev: {
  neossh = final.callPackage ./neossh.nix { };
  notion-mcp-server = final.callPackage ./notion-mcp-server { };
  pi-coding-agent = final.callPackage ./pi-coding-agent { };
}
