-- nvim-notify: toast notifications in the top-right corner.
-- color.lua sets Normal bg=none, so the toast needs an explicit background.
local function background()
  local bg = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg
  if bg then
    return string.format("#%06x", bg)
  end
  return "#282a36"
end

local notify = require("notify")
notify.setup({
  background_colour = background(),
  stages = "fade_in_slide_out",
  timeout = 3000,
  max_width = 60,
  top_down = true,
})
vim.notify = notify
