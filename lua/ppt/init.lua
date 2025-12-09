local parser = require("ppt.parser")
local executor = require("ppt.executor")
local window = require("ppt.window")

local M = {}

-- plugin options
local options = {
  executors = {
    javascript = executor.create_code_executor("node"),
    python = executor.create_code_executor("python"),
  },
}

--- Setup plugin with user options
--- @param opts table|nil: User options
function M.setup(opts)
  opts = opts or {}
  opts.executors = opts.executors or {}

  -- Merge user code executors with defaults
  -- "force" uses values from rightmost table
  -- i.e. user opts in our case
  options.executors = vim.tbl_extend("force", options.executors, opts.executors)
end

--- Render slide content to windows
--- @param state table: State object
local function render_slide(state)
  local slide = state.parsed.slides[state.slide_idx]
  local width = vim.o.columns
  local padding = string.rep(" ", (width - #slide.title) / 2)
  local centered_title = padding .. slide.title

  vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { centered_title })
  vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)

  local footer = string.format(" %d / %d | %s", state.slide_idx, #state.parsed.slides, state.title)
  vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
end

--- Start PPT presentation
--- @param opts table|nil: Options for starting PPT
function M.start_ppt(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local state = {
    parsed = {},
    slide_idx = 1,
    floats = {},
    title = "",
    restore_opts = {},
  }

  state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  -- Parse slides
  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.parsed = parser.parse_slides(lines)

  -- Create windows
  state.floats = window.create_ppt_windows()

  -- Set markdown filetype for all buffers
  for _, float in pairs(state.floats) do
    vim.bo[float.buf].filetype = "markdown"
  end

  -- ppt plugin will setup some nvim options
  -- restore options revert back to user options when plugin is closed
  state.restore_opts = {
    cmdheight = {
      original = vim.o.cmdheight,
      ppt = 0,
    },
  }

  for option, cfg in pairs(state.restore_opts) do
    vim.opt[option] = cfg.ppt
  end

  -- helper function to setup kepmap
  local body_buf = state.floats.body.buf
  local function set_keymap(mode, key, callback)
    vim.keymap.set(mode, key, callback, {
      -- setup keymap for the ppt buffer only
      -- we don't wanna mess with user's global keymaps
      buffer = body_buf,
    })
  end

  -- Navigate to next slide
  set_keymap("n", "n", function()
    state.slide_idx = math.min(state.slide_idx + 1, #state.parsed.slides)
    render_slide(state)
  end)

  -- Navigate to previous slide
  set_keymap("n", "p", function()
    state.slide_idx = math.max(state.slide_idx - 1, 1)
    render_slide(state)
  end)

  -- Close PPT window
  set_keymap("n", "q", function()
    vim.api.nvim_win_close(state.floats.body.win, true)
  end)

  -- Execute code block
  set_keymap("n", "X", function()
    local slide = state.parsed.slides[state.slide_idx]
    if not slide then
      return
    end

    local block = slide.blocks[1]
    if not block then
      print("No blocks on this slide")
      return
    end

    local executor_fn = options.executors[block.language]
    if not executor_fn then
      print(string.format("WARN: no way to execute the %s code!!!", block.language))
      return
    end

    local output = executor_fn(block)
    local formatted = executor.format_code_output(block, output)

    -- Create output window
    local temp_width = math.floor(0.6 * vim.o.columns)
    local temp_height = math.floor(0.6 * vim.o.lines)
    local output_win = window.create_code_output_window(temp_width, temp_height)

    vim.api.nvim_buf_set_lines(output_win.buf, 0, -1, false, formatted)
  end)

  -- Setup autocmds
  local augroup = vim.api.nvim_create_augroup("ppt", { clear = true })

  -- Cleanup on buffer leave
  vim.api.nvim_create_autocmd("BufLeave", {
    group = augroup,
    buffer = state.floats.body.buf,
    callback = function()
      -- Restore user options
      for option, cfg in pairs(state.restore_opts) do
        vim.opt[option] = cfg.original
      end

      -- Close all floating windows
      window.close_all_floats(state.floats)
    end,
  })

  -- Handle window resize
  vim.api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
      if state.floats.body.win == nil or not vim.api.nvim_win_is_valid(state.floats.body.win) then
        return
      end

      window.update_window_configs(state.floats)
      render_slide(state)
    end,
  })

  -- Render initial slide
  render_slide(state)
end

-- Expose parser for testing
M._parse_slides = parser.parse_slides

return M
