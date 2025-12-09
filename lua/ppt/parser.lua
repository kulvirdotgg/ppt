--- @class ppt.Slides
--- @field slides ppt.Slide[]: The slides of file

--- @class ppt.Slide
--- @field title string: Title of the slide
--- @field body string[]: body of the slide
--- @field blocks ppt.Block[]: A codeblock inside of a slide

--- @class ppt.Block
--- @field language string: language used in the codeblock
--- @field code string: the actual code in the block

local M = {}

--- Parse markdown lines into slides
--- @param lines string[]: The lines in the buffer
--- @return ppt.Slides
function M.parse_slides(lines)
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

  -- extract code blocks from each slide
  for _, slide in ipairs(slides.slides) do
    M._extract_code_blocks(slide)
  end

  return slides
end

--- Extract code blocks from a slide's body
--- @param slide ppt.Slide: The slide to extract code blocks from
function M._extract_code_blocks(slide)
  local block = {
    language = nil,
    code = "",
  }
  local inside_block = false

  for _, line in ipairs(slide.body) do
    if vim.startswith(line, "```") then
      if not inside_block then
        inside_block = true
        -- first 3 chars are ticks "```"
        block.language = string.sub(line, 4)
        block.code = ""
      else
        inside_block = false
        block.code = vim.trim(block.code)
        table.insert(slide.blocks, block)
        block = {
          language = nil,
          code = "",
        }
      end
    else
      -- inside the markdown block
      if inside_block then
        block.code = block.code .. line .. "\n"
      end
    end
  end
end

return M

