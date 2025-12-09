# `ppt.nvim`

A cool yet simple `nvim` plugin to make ppt slides from the markdown file.

We all love markdown and it is objectively the best format to write stuff in.
Also we all hate *Micros\*ft* stuff, so its just a simple plugin to make PPTs with everyone's favourite text editor nvim using markdown.
On top of that this plugin comes with features like execute the code present inside the codeblocks of your slides and I think thats pretty cool.

## Installation

**Lazy Pacakage Manager**:

```lua
{
  "kulvirdotgg/ppt.nvim",
  config = function()
    require("ppt").setup()
  end,
}
```

## Usage

Open a markdown file and start the presentation:

```lua
require("ppt").start_ppt()
```

Or use the command:

```sh
:PptStart
```

- `n` - Navigate to **next** slide
- `p` - Navigate to **previous** slide
- `X` - **Execute** code block (if present on current slide)
- `q` or `<Esc>` - **Quit** presentation


## Configuration

The plugin comes with capabilities to execute **JavaScript** and **Python** code from code blocks.

You can add execution commands for other programming languages by providing the command to run:

```lua
require("ppt").setup({
  executors = {
    -- Override default Python executor
    python = "python3",
    
    -- Add execution commands for other languages
    -- The command will be used to execute the code block
    -- Make sure the executable is installed and available in your PATH
    lua = "lua",
    bash = "bash",
    rust = "rustc --script",
  },
})
```

**Note**: The executor value must be a string representing the command to execute. The plugin will create a temporary file with your code and run the specified command on it.

