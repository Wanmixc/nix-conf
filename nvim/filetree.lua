-- nvim-tree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
vim.keymap.set("n", "<leader>tt", ":NvimTreeToggle<CR>")
vim.keymap.set("n", "<leader>tr", ":NvimTreeRefresh<CR>")
vim.keymap.set("n", "<leader>tn", ":NvimTreeFindFile<CR>")

require("nvim-tree").setup({
  view = {
    side = "right",
    width = 40,
  },
  diagnostics = {
    enable = true,
    show_on_dirs = true,
  },
})
