-- lsp (neovim 0.11 native vim.lsp.config)
-- Suppress nvim-lspconfig framework deprecation at the source
local _deprecate = vim.deprecate
vim.deprecate = function(name, ...)
  if name == 'require("lspconfig")' then return end
  return _deprecate(name, ...)
end

local tabnine = require("cmp_tabnine.config")

tabnine:setup({
  max_lines = 1000,
  max_num_results = 5,
  sort = true,
  run_on_every_keystroke = true,
  snippet_placeholder = "..",
})

local source_mapping = {
  luasnip = "[Snip]",
  cmp_tabnine = "[TN]",
  ["vim-dadbod-completion"] = "[DB]",
  nvim_lsp = "[LSP]",
  otter = "[Otter]",
  buffer = "[Buff]",
  path = "[Path]",
}

local lspkind = require("lspkind")
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    { name = "otter" },
    { name = "vim-dadbod-completion" },
    { name = "luasnip" },
    { name = "cmp_tabnine" },
    { name = "nvim_lsp" },
    { name = "buffer" },
  }),
  formatting = {
    format = function(entry, vim_item)
      vim_item.kind = lspkind.presets.default[vim_item.kind]
      local menu = source_mapping[entry.source.name]
      if entry.source.name == "cmp_tabnine" then
        if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
          menu = entry.completion_item.data.detail .. " " .. menu
        end
        vim_item.kind = ""
      end
      vim_item.menu = menu
      return vim_item
    end,
  },
})

-- Diagnostic keymaps
vim.keymap.set("n", "ge", function() vim.diagnostic.open_float(0, { scope = "line", border = "single" }) end)
vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end)
vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end)
vim.keymap.set("n", "<leader>dq", function() vim.diagnostic.setloclist() end)

-- LSP keymaps set via LspAttach autocmd
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
    vim.keymap.set("n", "gvd", "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", { buffer = bufnr })
    vim.keymap.set("n", "gsd", "<cmd>split | lua vim.lsp.buf.definition()<CR>", { buffer = bufnr })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr })
    vim.keymap.set("n", "<C-q>", vim.lsp.buf.signature_help, { buffer = bufnr })
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, { buffer = bufnr })
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, { buffer = bufnr })
    vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, { buffer = bufnr })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr })
    vim.keymap.set("n", "<space>fo", function() vim.lsp.buf.format({ timeout_ms = 5000 }) end, { buffer = bufnr })
  end,
})

-- Fold capabilities for ufo
local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- ── Server configs via native vim.lsp.config (neovim 0.11+) ──────────────

local function setup(name, opts)
  opts = vim.tbl_deep_extend("force", opts or {}, { capabilities = capabilities })
  pcall(vim.lsp.config, name, opts)
  pcall(vim.lsp.enable, name)
end

setup("astro", {})
setup("bashls", {})
setup("clangd", {})
setup("cmake", {})
setup("diagnosticls", {})
setup("dockerls", {})
setup("emmet_ls", {})
setup("gleam", {})
setup("gopls", {})
setup("graphql", {})
setup("hls", {})
setup("html", {})
setup("intelephense", {})
setup("jsonls", {})
setup("nixd", {})
setup("ocamllsp", {})
setup("prismals", {})
setup("pyright", {})
setup("quick_lint_js", {})
setup("svelte", {})
setup("tailwindcss", {})
setup("taplo", {})
setup("texlab", {})
setup("tflint", {})
setup("vimls", {})
setup("wgsl_analyzer", {})
setup("yamlls", {})

-- ts_ls with inlay hints
setup("ts_ls", {
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
})
