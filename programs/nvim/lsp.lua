-- lsp (neovim 0.11 native vim.lsp.config)
-- Suppress nvim-lspconfig framework deprecation at the source
local _deprecate = vim.deprecate
vim.deprecate = function(name, ...)
  if name == 'require("lspconfig")' then return end
  return _deprecate(name, ...)
end

local source_mapping = {
  luasnip = "[Snip]",
  ["vim-dadbod-completion"] = "[DB]",
  nvim_lsp = "[LSP]",
  otter = "[Otter]",
  buffer = "[Buff]",
  path = "[Path]",
}

local lspkind = require("lspkind")
local cmp = require("cmp")
local luasnip = require("luasnip")

require("luasnip.loaders.from_vscode").lazy_load({ include = { "cs" } })
luasnip.add_snippets("cs", {
  luasnip.snippet("httpget", {
    luasnip.text_node('[HttpGet("'),
    luasnip.insert_node(1),
    luasnip.text_node('")]'),
    luasnip.insert_node(0),
  }),
})

require("lsp-endhints").setup({
  autoEnableHints = false,
  icons = { type = ":", parameter = "", offspec = "", unknown = "" },
})

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<C-j>"] = cmp.mapping(function(fallback)
      if luasnip.jumpable(1) then luasnip.jump(1) else fallback() end
    end, { "i", "s" }),
    ["<C-k>"] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    { name = "otter" },
    { name = "vim-dadbod-completion" },
    { name = "luasnip" },
    { name = "nvim_lsp" },
    { name = "buffer" },
  }),
  formatting = {
    format = function(entry, vim_item)
      vim_item.kind = lspkind.presets.default[vim_item.kind]
      local menu = source_mapping[entry.source.name]
      vim_item.menu = menu
      return vim_item
    end,
  },
})

-- Roslyn displays generic types with <> but inserts only the type name.
cmp.event:on("confirm_done", function(event)
  local entry = event.entry
  if entry.source.name ~= "nvim_lsp" then return end
  local client = entry.source.source.client
  if not client or client.name ~= "roslyn_ls" then return end

  local item = entry.completion_item
  local name = item.label:match("^([%w_]+)<>$")
  if not name then return end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if line:sub(col - #name + 1, col) ~= name or line:sub(col + 1, col + 1) == "<" then return end

  local brackets = line:sub(col + 1, col + 1) == ">" and "<" or "<>"
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { brackets })
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })
end)

-- Config in `~/configuration` powers `~/.config/nvim` (Nix symlink).
-- Disable inline diagnostics with:
--   vim.g.nvim_diagnostics_enable = false
-- in `config.lua`.
vim.diagnostic.config({
  virtual_text = vim.g.nvim_diagnostics_enable,
  signs = vim.g.nvim_diagnostic_signs,
  underline = true,
  float = true,
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
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
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
    vim.keymap.set("n", "<space>fo", function()
      if vim.bo[bufnr].filetype ~= "cs" then
        vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 5000 })
        return
      end
      local roslyn = vim.lsp.get_clients({ bufnr = bufnr, name = "roslyn_ls" })[1]
      if not roslyn or not roslyn:supports_method("textDocument/formatting") then
        vim.notify("C# formatting unavailable: Roslyn is not attached", vim.log.levels.WARN)
        return
      end
      local response, err = roslyn:request_sync("textDocument/formatting", vim.lsp.util.make_formatting_params({}), 5000, bufnr)
      if not response or response.err then
        vim.notify("C# formatting failed: " .. tostring(err or (response and response.err.message)), vim.log.levels.ERROR)
        return
      end
      if response.result and response.result ~= vim.NIL then
        vim.lsp.util.apply_text_edits(response.result, bufnr, roslyn.offset_encoding)
      end
      dofile(vim.fn.stdpath("config") .. "/csharp-align.lua")(bufnr)
    end, { buffer = bufnr })
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

local function setup_roslyn_ls()
  pcall(vim.lsp.config, "roslyn_ls", { capabilities = capabilities })

  local function start_roslyn(bufnr)
    if #vim.lsp.get_clients({ bufnr = bufnr, name = "roslyn_ls" }) > 0 then
      return
    end

    local root_dir = vim.fs.root(bufnr, function(name)
      return name:match("%.slnx?$") ~= nil or name:match("%.csproj$") ~= nil
    end)
    if not root_dir then
      return
    end

    local config = vim.tbl_deep_extend("force", vim.deepcopy(vim.lsp.config.roslyn_ls), {
      capabilities = capabilities,
      root_dir = root_dir,
      -- The nixpkgs launcher resets DOTNET_ROOT from PATH; the apphost prefers this x64 override.
      cmd_env = vim.env.ROSLYN_DOTNET_ROOT and {
        DOTNET_ROOT = vim.env.ROSLYN_DOTNET_ROOT,
        DOTNET_ROOT_X64 = vim.env.ROSLYN_DOTNET_ROOT,
      } or {},
    })

    vim.api.nvim_buf_call(bufnr, function()
      vim.lsp.start(config)
    end)
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function(args)
      start_roslyn(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    pattern = "*.cs",
    callback = function(args)
      start_roslyn(args.buf)
    end,
  })

  vim.schedule(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr):match("%.cs$") then
        start_roslyn(bufnr)
      end
    end
  end)
end

setup_roslyn_ls()

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
