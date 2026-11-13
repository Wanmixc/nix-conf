{ pkgs, ... }:
let
  inherit (pkgs.vimPlugins)
    dracula-vim
    nvim-lspconfig
    cmp-nvim-lsp
    cmp-buffer
    nvim-cmp
    luasnip
    lspkind-nvim
    null-ls-nvim
    markdown-preview-nvim
    nvim-jdtls
    dressing-nvim
    rustaceanvim
    nvim-notify
    neoconf-nvim
    nvim-tree-lua
    nvim-web-devicons
    bufferline-nvim
    toggleterm-nvim
    indent-blankline-nvim
    rainbow-delimiters-nvim
    promise-async
    nvim-ufo
    lualine-nvim
    nvim-colorizer-lua
    octo-nvim
    vim-fugitive
    gitsigns-nvim
    trouble-nvim
    vim-dadbod
    vim-dadbod-ui
    vim-dadbod-completion
    otter-nvim
    nvim-autopairs
    comment-nvim
    nvim-ts-context-commentstring
    nvim-ts-autotag
    vim-move
    vim-visual-multi
    vim-surround
    telescope-nvim
    auto-save-nvim
    refactoring-nvim
    nvim-spectre
    auto-session
    nvim-dap
    nvim-dap-ui
    nvim-dap-virtual-text
    telescope-dap-nvim
    nvim-dap-go
    popup-nvim
    plenary-nvim
    registers-nvim
    vim-suda
    nui-nvim
    harpoon
    vim-sneak
    nvim-config-local
    playground
    nvim-treesitter
    nvim-treesitter-parsers
    ;

  dotnetSdk = pkgs.dotnetCorePackages.sdk_10_0;
  roslynRuntime = pkgs.dotnetCorePackages.runtime_9_0;
  lsp-endhints = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-lsp-endhints";
    version = "unstable-3224a1c";
    src = pkgs.fetchFromGitHub {
      owner = "chrisgrieser";
      repo = "nvim-lsp-endhints";
      rev = "3224a1c1b2fe1b067049764a154d4d727425fa6d";
      hash = "sha256-OYINp7BgZ108BnGGAiB9teis9TRIw4C+afX9rvByt2Q=";
    };
  };
in
{
  xdg.configFile = {
    "nvim/CHEATSHEET.md".source = ./CHEATSHEET.md;
    "nvim/entry.lua".source = ./entry.lua;
    "nvim/autopairs.lua".source = ./autopairs.lua;
    "nvim/autosave.lua".source = ./autosave.lua;
    "nvim/bufferline.lua".source = ./bufferline.lua;
    "nvim/color.lua".source = ./color.lua;
    "nvim/comment.lua".source = ./comment.lua;
    "nvim/config.lua".source = ./config.lua;
    "nvim/dap.lua".source = ./dap.lua;
    "nvim/filetree.lua".source = ./filetree.lua;
    "nvim/fold.lua".source = ./fold.lua;
    "nvim/gitsigns.lua".source = ./gitsigns.lua;
    "nvim/harpoon.lua".source = ./harpoon.lua;
    "nvim/indentline.lua".source = ./indentline.lua;
    "nvim/keymap.lua".source = ./keymap.lua;
    "nvim/local.lua".source = ./local.lua;
    "nvim/lsp.lua".source = ./lsp.lua;
    "nvim/lualine.lua".source = ./lualine.lua;
    "nvim/notify.lua".source = ./notify.lua;
    "nvim/refactoring.lua".source = ./refactoring.lua;
    "nvim/session.lua".source = ./session.lua;
    "nvim/spectre.lua".source = ./spectre.lua;
    "nvim/telescope.lua".source = ./telescope.lua;
    "nvim/toggleterm.lua".source = ./toggleterm.lua;
    "nvim/treesitter.lua".source = ./treesitter.lua;
    "nvim/config".source = ./config;
    "nvim/keymapconfig".source = ./keymapconfig;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      typescript-language-server
      typescript
      roslyn-ls
      dotnetSdk
    ];

    extraWrapperArgs = [
      "--set"
      "DOTNET_ROOT"
      "${dotnetSdk}/share/dotnet"
      "--set"
      "ROSLYN_DOTNET_ROOT"
      "${roslynRuntime}/share/dotnet"
    ];

    # Load the visible ~/.config/nvim/init.lua so the repo folder is the
    # visible config folder remains the source of truth while plugins still
    # come from Nix.
    extraLuaConfig = ''
      dofile(vim.fn.stdpath("config") .. "/entry.lua")
    '';

    plugins = [
      dracula-vim
      nvim-lspconfig
      lsp-endhints
      cmp-nvim-lsp
      cmp-buffer
      nvim-cmp
      luasnip
      lspkind-nvim
      null-ls-nvim
      markdown-preview-nvim
      nvim-jdtls
      dressing-nvim
      rustaceanvim
      nvim-notify
      neoconf-nvim
      nvim-tree-lua
      nvim-web-devicons
      bufferline-nvim
      toggleterm-nvim
      indent-blankline-nvim
      rainbow-delimiters-nvim
      promise-async
      nvim-ufo
      lualine-nvim
      nvim-colorizer-lua
      octo-nvim
      vim-fugitive
      gitsigns-nvim
      trouble-nvim
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      otter-nvim
      nvim-autopairs
      comment-nvim
      nvim-ts-context-commentstring
      nvim-ts-autotag
      vim-move
      vim-visual-multi
      vim-surround
      telescope-nvim
      auto-save-nvim
      refactoring-nvim
      nvim-spectre
      auto-session
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      telescope-dap-nvim
      nvim-dap-go
      popup-nvim
      plenary-nvim
      registers-nvim
      vim-suda
      nui-nvim
      harpoon
      vim-sneak
      nvim-config-local
      playground
      (
        nvim-treesitter.withPlugins (
          _: nvim-treesitter.allGrammars ++ [
            nvim-treesitter-parsers.wgsl
            nvim-treesitter-parsers.astro
          ]
        )
      )
    ];
  };
}
