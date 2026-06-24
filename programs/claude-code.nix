{ pkgs, ... }:
let
  claudeCodePkg = pkgs.claude-code.overrideAttrs (_oldAttrs: {
    version = "2.1.187";

    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.187/linux-x64/claude";
      sha256 = "sha256-uwL8szYm+MWZ0Q2L7jhYXUz41CJcO0l4ad7nRU5782E=";
    };
  });
in
{
  home.packages = [ claudeCodePkg ];
}
