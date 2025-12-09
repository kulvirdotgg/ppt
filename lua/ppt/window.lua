local M = {}

--- Create a floating window (private)
--- @param config table: Window configuration
--- @param enter boolean|nil: Whether to enter the window
--- @return table: {buf: integer, win: integer}
local function create_floating_window(config, enter)
  if enter == nil then
    enter = false
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, enter or false, config)

  return { buf = buf, win = win }
end

--- Create window configurations for PPT presentation
--- @return table: Window configurations for background, header, body, footer
local function create_window_configs()
  local width = vim.o.columns
  local height = vim.o.lines

  local header_height = 1 + 2 -- 1 + border
  local footer_height = 1 -- 1
  local body_height = height - header_height - footer_height - 4

  return {
    background = {
      relative = "editor",
      width = width,
      height = height,
      style = "minimal",
      col = 0,
      row = 0,
      zindex = 1,
      border = "none",
    },
    header = {
      relative = "editor",
      width = width,
      height = 1,
      style = "minimal",
      col = 0,
      row = 0,
      border = "rounded",
      zindex = 2,
    },
    body = {
      relative = "editor",
      width = width - 8,
      height = body_height,
      style = "minimal",
      col = 8,
      row = 4,
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
    },
    footer = {
      relative = "editor",
      width = width,
      height = 1,
      style = "minimal",
      border = "none",
      col = 0,
      row = height - 1,
      zindex = 2,
    },
  }
end

--- Create all PPT windows
--- @return table: Table of floating windows
function M.create_ppt_windows()
  local win_configs = create_window_configs()
  return {
    background = create_floating_window(win_configs.background),
    header = create_floating_window(win_configs.header),
    body = create_floating_window(win_configs.body, true),
    footer = create_floating_window(win_configs.footer),
  }
end

--- Update window configurations on resize
--- @param floats table: Table of floating windows
function M.update_window_configs(floats)
  local win_configs = create_window_configs()

  for name, float in pairs(floats) do
    vim.api.nvim_win_set_config(float.win, win_configs[name])
  end
end

--- Create a centered floating window for code execution output
--- @param width integer: Window width
--- @param height integer: Window height
--- @return table: {buf: integer, win: integer}
function M.create_code_output_window(width, height)
  local exec_code_buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(exec_code_buf, true, {
    relative = "editor",
    style = "minimal",
    noautocmd = true,
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
  })

  vim.bo[exec_code_buf].filetype = "markdown"

  return { buf = exec_code_buf, win = win }
end

--- Close all floating windows
--- @param floats table: Table of floating windows
function M.close_all_floats(floats)
  for _, float in pairs(floats) do
    pcall(vim.api.nvim_win_close, float.win, true)
  end
end

return M
