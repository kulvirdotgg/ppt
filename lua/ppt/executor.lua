local M = {}

--- @param program string: (eg: "node", "python")
--- @return fun(block: ppt.Block): string[]
function M.create_code_executor(program)
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

--- Format code output for display
--- @param block ppt.Block: The code block that was executed
--- @param output string[]: The output from execution
--- @return string[]
function M.format_code_output(block, output)
  local formatted = { "# code", "", "```" .. block.language }
  vim.list_extend(formatted, vim.split(block.code, "\n"))
  table.insert(formatted, "```")

  table.insert(formatted, "")
  table.insert(formatted, "# Output")
  table.insert(formatted, "")
  table.insert(formatted, "```")
  table.insert(formatted, "")
  vim.list_extend(formatted, output)
  table.insert(formatted, "```")

  return formatted
end

return M
