--[[

in plugin/conquer.vim

nnoremap <Plug>ConquerWin :lua require('conquer').make_command_window()<CR>

nmap ,cw <Plug>ConquerWin


TODO:
- change the borderchars for the Borders to be a thin line along the bottom
- Fix key_enter leaving around a ton of buffers and windows
  (they're sitting behidn the current buffer and window... that's kind of annoying)
- Provide keymap configuration, color configuration, etc.
- Update readme to show that you should really install nvim-lua/popup.nvim
    this is so you can have pretty borders
- Make a "move from regular command line to floating command line"
- Make a lua mode

--]]

-- For hot reloading of lua:
--  Now, when you re-luafile this file, it will load anew
package.loaded['conquer'] = nil

local has_popup, Border = pcall(require, 'popup.border')
local associated_windows = {}
local default_width = 40

local conquer = {}

conquer.float_command_line = function()
  local cmd_line = vim.fn.getcmdline()
end

local make_window = function(height, width, row, columns, enter)
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = columns,
    style = 'minimal',
  }

  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, enter, win_opts)

  associated_windows[bufnr] = {win_id}

  if has_popup then
    local border = Border:new(bufnr, win_id, win_opts, {})
    vim.api.nvim_win_set_option(border.win_id, 'winhl', 'Normal:Normal')

    table.insert(associated_windows[bufnr], border.win_id)
  end

  return win_id, bufnr
end

conquer._clear_window = function(bufnr)
  if not associated_windows[bufnr] then
    return
  end

  for _, v in ipairs(associated_windows[bufnr]) do
    pcall(vim.api.nvim_win_close, v, true)
  end

  associated_windows[bufnr] = nil
end

conquer.make_command_window = function()
  local win_id, bufnr = make_window(
    1,
    default_width,
    math.floor(vim.o.lines / 2),
    math.floor(vim.o.columns / 2) - (default_width / 2),
    true
  )

  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'vim')
  vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:Normal')


  -- vim.api.nvim_buf_set_keymap(0, 'i', 'x', 'zzz', {})

  vim.cmd [[startinsert]]

  -- TODO:... we could defer this?
  -- TODO: The other option is wait until TJ's PR lands for handling keystrokes
  -- TODO: Tell haorenw that we don't wnat him to override this... :)
  -- TODO: Make these configurable
  local map_string = string.format(
    "<c-o>:lua require('conquer').key_enter(%s)<CR>",
    bufnr
  )
  local map_opts = {
    noremap = true,
    silent = true,
  }

  vim.api.nvim_buf_set_keymap(0, 'i', '<CR>', map_string, map_opts)
  vim.api.nvim_buf_set_keymap(0, 'i', '<M-CR>', map_string, map_opts)

  vim.cmd(string.format(
    [[autocmd BufLeave <buffer=%s> ++nested :lua require('conquer')._clear_window(%s)]],
    bufnr,
    bufnr
  ))

  return win_id, bufnr
end

conquer.key_enter = function(og_bufnr)
  local lines = vim.api.nvim_buf_get_lines(0, 0, 1, false)
  local results = vim.fn.execute(lines)  -- Do not recalculate
  local results_pretty = vim.split(results, "\n")

  -- Copy into the '*' register
  vim.fn.setreg('*', results)

  -- Clear the empty line if it is at the beginning.
  if results_pretty[1] == "" then
    table.remove(results_pretty, 1)
  end

  local win_id, bufnr = make_window(
    #results_pretty,
    default_width,
    math.floor(vim.o.lines / 2) + 3,
    math.floor(vim.o.columns / 2) - (default_width / 2),
    false
  )

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, results_pretty)
  vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:Error')

  if not associated_windows[og_bufnr] then
    vim.api.nvim_win_close(win_id, true)
  else
    table.insert(associated_windows[og_bufnr], win_id)
  end
end

return conquer
