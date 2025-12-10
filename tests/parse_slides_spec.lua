---@diagnostic disable: undefined-field

local ppt = require("ppt")
local parse_slides = ppt._parse_slides

local eq = assert.are.same

describe("ppt.parse_slides", function()
  it("should parse an empty file", function()
    eq({
      slides = {
        {
          title = "",
          body = {},
          blocks = {},
        },
      },
    }, parse_slides({}))
  end)

  it("should parse a file with one slide", function()
    eq(
      {
        slides = {
          {
            title = "# Title of the slide",
            body = { "my body!!! my body" },
            blocks = {},
          },
        },
      },
      parse_slides({
        "# Title of the slide",
        "my body!!! my body",
      })
    )
  end)

  it("should parse a file with one slide, and a block", function()
    local parsed = parse_slides({
      "# Title of the slide",
      "my body!!! my body",
      "```lua",
      "print(meow)",
      "```",
    })

    -- parsed slides len should be 1
    -- because we are parsing only 1 slide
    eq(1, #parsed.slides)

    local slide = parsed.slides[1]

    -- title of parsed slide should match actual title
    eq("# Title of the slide", slide.title)

    eq({
      "my body!!! my body",
      "```lua",
      "print(meow)",
      "```",
    }, slide.body)

    eq({
      language = "lua",
      code = "print(meow)",
    }, slide.blocks[1])
  end)

  it("should handle multiple code blocks in one slide", function()
    local parsed = parse_slides({
      "# Slide with Multiple Blocks",
      "Some content",
      "```javascript",
      "console.log('meow')",
      "```",
      "More content",
      "```python",
      "print('meow')",
      "```",
    })

    local slide = parsed.slides[1]
    eq(2, #slide.blocks)

    eq("javascript", slide.blocks[1].language)
    eq("python", slide.blocks[2].language)

    eq("console.log('meow')", slide.blocks[1].code)
    eq("print('meow')", slide.blocks[2].code)
  end)
end)

