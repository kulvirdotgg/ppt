vim.api.nvim_create_user_command("PptStart", function()
  require("ppt").start_ppt()
end, {})
