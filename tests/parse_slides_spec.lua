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
          },
        },
      },
      parse_slides({
        "# Title of the slide",
        "my body!!! my body",
      })
    )
  end)
end)
