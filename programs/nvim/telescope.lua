-- telescope
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>")
vim.keymap.set("n", "<leader>fl", ":Telescope git_files<CR>")
vim.keymap.set("n", "<leader>fk", ":Telescope keymaps<CR>")
vim.keymap.set("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>")
vim.keymap.set("n", "<leader>fd", ":Telescope diagnostics<CR>")
vim.keymap.set(
  "n",
  "<leader>fc",
  ":Telescope current_buffer_fuzzy_find fuzzy=false case_mode=ignore_case previewer=false<CR>"
)

local telescope = require("telescope")
telescope.setup({
  defaults = {
    mappings = {
      n = {
        ["q"] = require("telescope.actions").close,
      },
    },
  },
})
telescope.load_extension("dap")
