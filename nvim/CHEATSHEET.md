# Neovim Keybindings Cheatsheet
> Leader key: `<Space>`

---

## General
| Key | Mode | Action |
|-----|------|--------|
| `jj` | i | Exit insert mode |
| `<leader>q` | n | Close buffer |
| `<leader><leader>x` | n | Reload nvim config |
| `:BufOnly` | cmd | Close all buffers except current |

---

## File & Search (Telescope)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>ff` | n | Find files |
| `<leader>fg` | n | Live grep |
| `<leader>fb` | n | List buffers |
| `<leader>fh` | n | Help tags |
| `<leader>fl` | n | Git files |
| `<leader>fk` | n | Keymaps |
| `<leader>fc` | n | Fuzzy find in current buffer |
| `<leader>fm` | n | Harpoon marks |

---

## File Tree (nvim-tree)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>e` | n | Toggle file tree |
| `<leader>tt` | n | Toggle file tree |
| `<leader>tr` | n | Refresh file tree |
| `<leader>tn` | n | Find current file in tree |

---

## Buffer Management (bufferline)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>l` | n | Next buffer |
| `<leader>h` | n | Previous buffer |
| `<leader>L` | n | Move buffer right |
| `<leader>H` | n | Move buffer left |
| `<leader>1..9` | n | Go to buffer 1–9 |

---

## Window & Split
| Key | Mode | Action |
|-----|------|--------|
| `<leader>s` | n | Horizontal split |
| `<leader>v` | n | Vertical split |
| `<leader>m` | n | Maximize / restore window |
| `<C-k>` | n | Resize +2 (height) |
| `<C-j>` | n | Resize -2 (height) |
| `<C-l>` | n | Resize +2 (width) |
| `<C-h>` | n | Resize -2 (width) |

---

## Editing
| Key | Mode | Action |
|-----|------|--------|
| `<leader>y` | n / v | Yank to system clipboard |
| `<leader>Y` | n | Yank to end of line → clipboard |
| `<leader>p` | n / v | Paste from clipboard |
| `<leader>P` | n / v | Paste before from clipboard |
| `<C-i>` | i | Insert 2 spaces (indent) |
| `jj` | i | Escape (from old config) |

---

## Git (gitsigns + fugitive)
| Key | Mode | Action |
|-----|------|--------|
| `]c` | n | Next hunk |
| `[c` | n | Previous hunk |
| `<leader>hs` | n / v | Stage hunk |
| `<leader>hr` | n / v | Reset hunk |
| `<leader>hS` | n | Stage entire buffer |
| `<leader>hu` | n | Undo stage hunk |
| `<leader>hR` | n | Reset entire buffer |
| `<leader>hp` | n | Preview hunk |
| `<leader>hb` | n | Blame line |
| `<leader>hd` | n | Diff this |
| `<leader>hD` | n | Diff this (~) |
| `<leader>tb` | n | Toggle line blame |
| `<leader>td` | n | Toggle deleted |
| `ih` | o / x | Select hunk (text object) |
| `<leader>gd` | n | Git diff split (fugitive) |
| `gdl` | n | Diffget from right |
| `gdh` | n | Diffget from left |

---

## LSP
| Key | Mode | Action |
|-----|------|--------|
| `gD` | n | Go to declaration |
| `gd` | n | Go to definition |
| `gvd` | n | Vertical split + definition |
| `gsd` | n | Horizontal split + definition |
| `K` | n | Hover |
| `gi` | n | Go to implementation |
| `gr` | n | References |
| `<C-q>` | n | Signature help |
| `<space>D` | n | Type definition |
| `<space>rn` | n | Rename |
| `<space>ca` | n | Code action |
| `<space>fo` | n | Format buffer |
| `ge` | n | Show diagnostic float |
| `[d` | n | Previous diagnostic |
| `]d` | n | Next diagnostic |
| `<leader>dq` | n | Diagnostic list to loclist |

---

## Terminal (toggleterm)
| Key | Mode | Action |
|-----|------|--------|
| `<C-\>` | n / i / t | Toggle terminal |
| `<esc>` | t | Exit terminal mode |
| `jk` | t | Exit terminal mode |
| `<C-h/j/k/l>` | t | Navigate windows from terminal |

---

## Debugging (nvim-dap)
| Key | Mode | Action |
|-----|------|--------|
| `<F5>` | n | Continue / Start |
| `<F3>` | n | Step over |
| `<F2>` | n | Step into |
| `<F4>` | n | Step out |
| `<leader>b` | n | Toggle breakpoint |
| `<leader>B` | n | Conditional breakpoint |
| `<leader>dm` | n | Log point message |
| `<leader>dr` | n | Open REPL |
| `<leader>do` | n | Toggle DAP UI |

---

## Refactoring
| Key | Mode | Action |
|-----|------|--------|
| `<leader>re` | v | Extract function |
| `<leader>rf` | v | Extract function to file |
| `<leader>rv` | v | Extract variable |
| `<leader>ri` | v / n | Inline variable |
| `<leader>rb` | n | Extract block |
| `<leader>rbf` | n | Extract block to file |

---

## Search & Replace (spectre)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>fr` | n | Open spectre |
| `<leader>fw` | n | Search word under cursor |
| `<leader>fw` | v | Search visual selection |
| `<leader>fe` | n | Search in current file |

---

## Harpoon (file marks)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>mm` | n | Add file |
| `<leader>mr` | n | Remove file |
| `<leader>mc` | n | Clear all marks |
| `<leader>mf` | n | Toggle quick menu |
| `<leader>ml` | n | Next mark |
| `<leader>mh` | n | Previous mark |

---

## Folding (nvim-ufo)
| Key | Mode | Action |
|-----|------|--------|
| `zR` | n | Open all folds |
| `zM` | n | Close all folds |

---

## Clipboard (system)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>y` | n / v | Yank to system clipboard |
| `<leader>Y` | n | Yank line to clipboard |
| `<leader>p` | n / v | Paste from clipboard |
| `<leader>P` | n / v | Paste before from clipboard |

---

## Misc Plugins
- **auto-save**: Automatically saves on `InsertLeave`, `TextChanged`, `BufLeave`, `FocusLost`
- **auto-session**: Restores last session automatically (suppressed in `~/` and `~/projects`)
- **nvim-colorizer**: Highlights color codes inline
- **nvim-autopairs**: Auto-closes `()`, `[]`, `{}`, `""`, `''`, ``
- **Comment.nvim**: Context-aware commenting via `ts_context_commentstring`
- **nvim-config-local**: Loads `.nvim.lua` / `.nvimrc` per project
- **fine-cmdline.nvim**: Enhanced command-line (`:`)
- **twoslash-queries.nvim**: TypeScript twoslash inline hints
- **mdx.nvim**: MDX syntax highlighting
