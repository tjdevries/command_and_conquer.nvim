package.loaded['conquer'] = nil

if true then
  vim.api.nvim_set_keymap(
    'n',
    ' :',
    ":lua require('conquer').make_command_window()<CR>",
    {
      noremap = true,
      silent = true,
    }
  )
end

-- require('conquer').make_command_window()
