-- Align assignment operators belonging to the same C# brace block.
return function(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "c_sharp")
  if not ok or not parser then
    vim.notify("C# alignment skipped: Tree-sitter parser unavailable", vim.log.levels.WARN)
    return
  end

  local groups, first_col = {}, {}
  local function visit(node, scope)
    for child in node:iter_children() do
      if child:type() == "{" then
        scope = node:id()
        break
      end
    end

    if scope and (node:type() == "assignment_expression" or node:type() == "variable_declarator") then
      for child in node:iter_children() do
        if child:type() == "=" then
          local row, col = child:start()
          first_col[row] = math.min(first_col[row] or col, col)
          groups[scope] = groups[scope] or {}
          table.insert(groups[scope], { row = row, col = col })
          break
        end
      end
    end
    for child in node:iter_children() do
      if child:named() then visit(child, scope) end
    end
  end

  local trees = parser:parse()
  if not trees[1] then return end
  visit(trees[1]:root(), nil)

  for _, group in pairs(groups) do
    local entries, prefixes = {}, {}
    for _, entry in ipairs(group) do
      if first_col[entry.row] == entry.col then
        local line = vim.api.nvim_buf_get_lines(bufnr, entry.row, entry.row + 1, false)[1]
        local prefix = line:sub(1, entry.col + 1)
        if not prefix:sub(1, -2):find("=", 1, true) then
          table.insert(entries, entry)
          table.insert(prefixes, prefix)
        end
      end
    end
    if #entries >= 2 then
      local aligned = require("mini.align").align_strings(prefixes, { split_pattern = "=", merge_delimiter = "" })
      for i, entry in ipairs(entries) do
        if aligned[i] ~= prefixes[i] then
          vim.api.nvim_buf_set_text(bufnr, entry.row, 0, entry.row, entry.col + 1, { aligned[i] })
        end
      end
    end
  end
end
