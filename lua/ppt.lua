local M = {}

M.setup = function()
  -- nothing here yet
end

local create_floating_window = function(config)
  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, config)

  return { buf = buf, win = win }
end

--- @class ppt.Slides
--- @field slides ppt.Slide[]: The slides of file

--- @class ppt.Slide
--- @field title string: Title of the slide
--- @field body string[]: body of the slide

--- Parses some lines
--- @param lines string[]: The lines in the buffer
--- @return ppt.Slides
local parse_slides = function(lines)
  local slides = { slides = {} }
  local curr_slide = {
    title = "",
    body = {},
  }

  local seperator = "^#"

  for _, line in ipairs(lines) do
    if line:find(seperator) then
      if #curr_slide.title > 0 then
        table.insert(slides.slides, curr_slide)
      end

      curr_slide = {
        title = line,
        body = {},
      }
    else
      table.insert(curr_slide.body, line)
    end

    table.insert(curr_slide, line)
  end

  table.insert(slides.slides, curr_slide)

  return slides
end

local create_window_configs = function()
  local width = vim.o.columns
  local height = vim.o.lines

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
      height = height - 6,
      style = "minimal",
      col = 8,
      row = 4,
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
    },
  }
end

M.start_ppt = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = parse_slides(lines)

  local win_configs = create_window_configs()

  -- create new window for ppt
  local background_float = create_floating_window(win_configs.background)
  local header_float = create_floating_window(win_configs.header)
  local body_float = create_floating_window(win_configs.body)

  vim.bo[header_float.buf].filetype = "markdown"
  vim.bo[body_float.buf].filetype = "markdown"

  -- keep track of what slide we are on
  local slide_idx = 1

  local set_slide_content = function(idx)
    local width = vim.o.columns
    local slide = parsed.slides[idx]
    local padding = string.rep(" ", (width - #slide.title) / 2)
    local title = padding .. slide.title

    vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
  end

  -- keymap to move to next slide
  vim.keymap.set("n", "n", function()
    slide_idx = math.min(slide_idx + 1, #parsed.slides)
    set_slide_content(slide_idx)
  end, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = body_float.buf,
  })

  -- keymap to move to prev slide
  vim.keymap.set("n", "p", function()
    slide_idx = math.max(slide_idx - 1, 1)
    set_slide_content(slide_idx)
  end, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = body_float.buf,
  })

  -- keymap to close the ppt window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(body_float.win, true)
  end, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = body_float.buf,
  })

  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      ppt = 0,
    },
  }

  -- set the options to desired values during ppt
  for option, cfg in ipairs(restore) do
    vim.opt[option] = cfg.ppt
  end

  -- when user leaves the PPT plugin window, resote user settings
  -- also, close the background, header windows toooo
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = body_float.buf,
    callback = function()
      -- restore the options to users options
      for option, cfg in ipairs(restore) do
        vim.opt[option] = cfg.original
      end

      pcall(vim.api.nvim_win_close, background_float.win, true)
      pcall(vim.api.nvim_win_close, header_float.win, true)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("ppt-resize", {}),
    callback = function()
      if body_float.win == nil or not vim.api.nvim_win_is_valid(body_float.win) then
        return
      end

      local updated_win_configs = create_window_configs()
      vim.api.nvim_win_set_config(header_float.win, updated_win_configs.header)
      vim.api.nvim_win_set_config(background_float.win, updated_win_configs.background)
      vim.api.nvim_win_set_config(body_float.win, updated_win_configs.body)

      set_slide_content(slide_idx)
    end,
  })

  set_slide_content(slide_idx)
end

M.start_ppt({ bufnr = 15 })

return M
