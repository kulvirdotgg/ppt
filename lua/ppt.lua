local M = {}

M.setup = function()
  -- nothing here yet
end

local create_floating_window = function(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- create a buffer
  local buf = vim.api.nvim_create_buf(false, true)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

--- @class ppt.Slides
--- @field slides string[]: The slides of file

--- Parses some lines
--- @param lines string[]: The lines in the buffer
--- @return ppt.Slides
local parse_slides = function(lines)
  local slides = { slides = {} }
  local curr_slide = {}

  local seperator = "^#"

  for _, line in ipairs(lines) do
    if line:find(seperator) then
      if #curr_slide > 0 then
        table.insert(slides.slides, curr_slide)
      end

      curr_slide = {}
    end

    table.insert(curr_slide, line)
  end

  table.insert(slides.slides, curr_slide)

  return slides
end

M.start_ppt = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = parse_slides(lines)

  -- create new window for ppt
  local float = create_floating_window()

  -- keep track of what slide we are on
  local slide_idx = 1

  -- keymap to move to next slide
  vim.keymap.set("n", "n", function()
    slide_idx = math.min(slide_idx + 1, #parsed.slides)
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[slide_idx])
  end, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = float.buf,
  })

  -- keymap to move to prev slide
  vim.keymap.set("n", "p", function()
    slide_idx = math.max(slide_idx - 1, 1)
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[slide_idx])
  end, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = float.buf,
  })

  -- keymap to close the ppt window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(float.win, true)
  end, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = float.buf,
  })

  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[1])
end

return M
