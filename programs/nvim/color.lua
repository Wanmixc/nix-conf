-- color
vim.api.nvim_command("colorscheme dracula")
vim.api.nvim_command("highlight Normal guibg=none ctermbg=none")

-- Visual selection: Dracula only links Visual, so Neovim's default
-- NvimDarkGrey4 (#4f5258) wins and nearly vanishes on the translucent
-- terminal background (1.88:1). Use a pale yellow block with dark text.
vim.api.nvim_command("highlight Visual guibg=#f1fa8c guifg=#24273a")
vim.api.nvim_command("highlight VisualNOS guibg=#f1fa8c guifg=#24273a")
vim.api.nvim_command("highlight WinBar guibg=#44475A")
vim.api.nvim_command("highlight WinSeparator guifg=None")
vim.api.nvim_command("highlight NvimTreeVertSplit guibg=None")
vim.api.nvim_command("hi LspInlayHint guifg=#f8f8f2 guibg=#44475A")

vim.api.nvim_command("highlight RainbowRed guifg=#E06C75 ctermfg=Red")
vim.api.nvim_command("highlight RainbowYellow guifg=#E5C07B ctermfg=Yellow")
vim.api.nvim_command("highlight RainbowBlue guifg=#61AFEF ctermfg=Blue")
vim.api.nvim_command("highlight RainbowGreen guifg=#98C379 ctermfg=Green")
vim.api.nvim_command("highlight RainbowViolet guifg=#C678DD ctermfg=Magenta")
vim.api.nvim_command("highlight RainbowCyan guifg=#56B6C2 ctermfg=Cyan")
