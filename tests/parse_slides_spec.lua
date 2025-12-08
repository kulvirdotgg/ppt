---@diagnostic disable: undefined-field

local parse_slides = require("ppt")._parse_slides

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
end)
