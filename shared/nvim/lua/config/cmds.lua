vim.api.nvim_create_user_command("Foreach", function (opts)
  local start_line = opts.line1
  local end_line = opts.line2
  local input_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local stdin_data = table.concat(input_lines, "\n") .. "\n"

  local shell_cmd = "xargs -I {} sh -c 'echo -n \"{}\" | " .. opts.args .. "'"

  local result = vim.fn.system(shell_cmd, stdin_data)

  local lines = vim.split(result, "\n")

  if lines[#lines] == "" then
    table.remove(lines)
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end, {
  nargs = "+",
  range = true,
})
