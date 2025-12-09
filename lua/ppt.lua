local M = {}

local create_floating_window = function(config, enter)
  if enter == nil then
    enter = false
  end

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, enter or false, config)

  return { buf = buf, win = win }
end

-- --- function to execute lua code
-- --- @param block ppt.Block: Block of code to execute
-- local execute_lua = function(block)
--   local original_print = print
--
--   local output = {}
--
--   print = function(...)
--     local args = { ... }
--     local message = table.concat(vim.tbl_map(tostring, args), "\t")
--     table.insert(output, message)
--   end
--
--   local chunk = loadstring(block.code)
--
--   pcall(function()
--     -- table.insert(output, "")
--     -- table.insert(output, "# Output")
--     -- table.insert(output, "")
--     if not chunk then
--       table.insert(output, "[[-- SKILL ISSUES --]]")
--     else
--       chunk()
--     end
--
--     return output
--   end)
--
--   print = original_print
--
--   return output
-- end

-- Function to execute the codeblock
M.execute_code_block = function(program)
  return function(block)
    -- create a temp file to store the code.
    local tempfile = vim.fn.tempname()
    -- write the code from codeblock to temp file
    vim.fn.writefile(vim.split(block.code, "\n"), tempfile)
    -- execute the temp file
    local result = vim.system({ program, tempfile }, { text = true }):wait()

    return vim.split(result.stdout, "\n")
  end
end

local options = {
  executors = {
    javascript = M.execute_code_block("node"),
    python = M.execute_code_block("python"),
  },
}

M.setup = function(opts)
  opts = opts or {}
  opts.executors = opts.executors or {}

  opts.executors.javascript = opts.executors or M.execute_code_block("node")
  opts.executors.python = opts.executors or M.execute_code_block("python")

  options = opts
end

--- @class ppt.Slides
--- @field slides ppt.Slide[]: The slides of file

--- @class ppt.Slide
--- @field title string: Title of the slide
--- @field body string[]: body of the slide
--- @field blocks ppt.Block[]: A codeblock inside of a slide

--- @class ppt.Block
--- @field language string: language used in the codeblock
--- @field code string: the actual code in the block

--- @param lines string[]: The lines in the buffer
--- @return ppt.Slides
local parse_slides = function(lines)
  local slides = { slides = {} }
  local curr_slide = {
    title = "",
    body = {},
    blocks = {},
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
        blocks = {},
      }
    else
      table.insert(curr_slide.body, line)
    end
  end

  table.insert(slides.slides, curr_slide)

  -- iterate over the slides and check for codeblocks
  for _, slide in ipairs(slides.slides) do
    local block = {
      language = nil,
      code = "",
    }
    local inside_block = false

    for _, line in ipairs(slide.body) do
      if vim.startswith(line, "```") then
        if not inside_block then
          inside_block = true

          -- first 3 chars are ticks
          block.language = string.sub(line, 4)
        else
          inside_block = false
          block.code = vim.trim(block.code)
          table.insert(slide.blocks, block)
        end
      else
        -- inside the markdown block
        if inside_block then
          block.code = block.code .. line .. "\n"
        end
      end
    end
  end

  return slides
end

local create_window_configs = function()
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
      -- TODO: a minimal border on top maybe!!!
      -- border = { " ", " ", " ", " ", " ", " ", " ", " " },
      border = "none",
      col = 0,
      row = height - 1,
      zindex = 2,
    },
  }
end

-- state objects for all methods to access
local state = {
  parsed = {},
  slide_idx = 1,
  floats = {},
}

local foreach_float = function(cb)
  for name, float in pairs(state.floats) do
    cb(name, float)
  end
end

local ppt_keymap = function(mode, keymap, cb)
  vim.keymap.set(mode, keymap, cb, {
    -- We don't want to set this keymap globally
    -- set this keymap for the slides buffer only
    buffer = state.floats.body.buf,
  })
end

M.start_ppt = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  state.slide_idx = 1
  state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.parsed = parse_slides(lines)

  local win_configs = create_window_configs()
  -- create new windows for ppt plugin
  -- header will contain the heading and centered
  -- background is just background KEKW!!
  -- body will have the content of slide
  -- Also Body window will have enter as true, i.e. enter only in the body window
  state.floats.background = create_floating_window(win_configs.background)
  state.floats.header = create_floating_window(win_configs.header)
  state.floats.body = create_floating_window(win_configs.body, true)
  state.floats.footer = create_floating_window(win_configs.footer)

  -- md filetype, for better looking md slides
  foreach_float(function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  -- keep track of what slide we are on

  local set_slide_content = function(idx)
    local width = vim.o.columns
    local slide = state.parsed.slides[idx]
    local padding = string.rep(" ", (width - #slide.title) / 2)
    local title = padding .. slide.title

    vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
    vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)
    local footer = string.format(" %d / %d | %s", state.slide_idx, #state.parsed.slides, state.title)
    vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
  end

  -- keymap to move to next slide
  ppt_keymap("n", "n", function()
    state.slide_idx = math.min(state.slide_idx + 1, #state.parsed.slides)
    set_slide_content(state.slide_idx)
  end)

  -- keymap to move to prev slide
  ppt_keymap("n", "p", function()
    state.slide_idx = math.max(state.slide_idx - 1, 1)
    set_slide_content(state.slide_idx)
  end)

  -- keymap to close the ppt window
  ppt_keymap("n", "q", function()
    vim.api.nvim_win_close(state.floats.body.win, true)
  end)

  -- keymap to execute the code inside the codeblock
  ppt_keymap("n", "X", function()
    local slide = state.parsed.slides[state.slide_idx]

    local block = slide.blocks[1]
    if not block then
      print("No blocks on this slide")
      return
    end

    local executors = options.executors[block.language]
    if not executors then
      print("WARN: no way to execute the %s code!!!", block.language)
      return
    end

    -- table for the message of the code block executed in the format:
    -- # Code
    -- ```typescript
    -- console.log("meow meow!!")
    -- ```
    -- # Output
    -- meow meow!!
    local output = { "# code", "", "```" .. block.language }
    vim.list_extend(output, vim.split(block.code, "\n"))
    table.insert(output, "```")

    table.insert(output, "")
    table.insert(output, "# Output")
    table.insert(output, "")
    table.insert(output, "```")
    table.insert(output, "")
    vim.list_extend(output, executors(block))
    table.insert(output, "```")

    -- new buffer and window to display executed code ouput
    -- keep it like half-ish the size of nvim window
    local temp_width = math.floor(0.6 * vim.o.columns)
    local temp_height = math.floor(0.6 * vim.o.lines)

    local exec_code_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(exec_code_buf, true, {
      relative = "editor",
      style = "minimal",
      noautocmd = true,
      width = temp_width,
      height = temp_height,
      row = math.floor((vim.o.lines - temp_height) / 2),
      col = math.floor((vim.o.columns - temp_width) / 2),
      border = "rounded",
    })

    vim.bo[exec_code_buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(exec_code_buf, 0, -1, false, output)
  end)

  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      ppt = 0,
    },
  }

  -- set the options to desired values during ppt
  for option, cfg in pairs(restore) do
    vim.opt[option] = cfg.ppt
  end

  -- when user leaves the PPT plugin window, resote user settings
  -- also, close the background, header windows toooo
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.floats.body.buf,
    callback = function()
      -- restore the options to users options
      for option, cfg in pairs(restore) do
        vim.opt[option] = cfg.original
      end

      foreach_float(function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("ppt-resize", {}),
    callback = function()
      if state.floats.body.win == nil or not vim.api.nvim_win_is_valid(state.floats.background.win) then
        return
      end

      local updated_win_configs = create_window_configs()
      foreach_float(function(name, float)
        vim.api.nvim_win_set_config(float.win, updated_win_configs[name])
      end)

      set_slide_content(state.slide_idx)
    end,
  })

  set_slide_content(state.slide_idx)
end

M._parse_slides = parse_slides

return M
