{ ... }:
{
  imports = [
    ./github.nix
    ./mimo.nix
    ./paste.nix
    ./supermemory.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.fish.shellInit = ''
    if test -f "$HOME/.config/runtime-env/paste.fish"
      source "$HOME/.config/runtime-env/paste.fish"
    end

    if test -f "$HOME/.config/runtime-env/gh.fish"
      source "$HOME/.config/runtime-env/gh.fish"
    end

    if test -f "$HOME/.config/runtime-env/supermemory.fish"
      source "$HOME/.config/runtime-env/supermemory.fish"
    end

    if test -f "$HOME/.config/runtime-env/mimo.fish"
      source "$HOME/.config/runtime-env/mimo.fish"
    end
  '';
}
