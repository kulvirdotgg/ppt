# `ppt.nvim`

A cool yet simple `nvim` plugin to make ppt slides from the markdown file.

We all love markdown and it is objectively the best format to write stuff in.
Also we all hate *Micros\*ft* stuff, so its just a simple plugin to make PPTs with everyone's favourite text editor nvim using markdown.

## Usage

```lua
require("ppt").start_ppt()
```

- Use `n` and `p` for navigating between slides.
    - `n` obviously means **Next**
    - `p` means **previous**

- Use `X` to execute the lua code inside the codeblocks
