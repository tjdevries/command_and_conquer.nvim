
--[[
function! LuaComplete (ArgLeaf, CmdLine, CursorPos) abort
        return map(luaeval("vim.tbl_keys(" . a:CmdLine[4:] . ")"), {k,v -> a:CmdLine[4:] . "." . v})
endfunction
--]]

local og_print = print
local print = function(...)
  print(vim.inspect(...))
end

local completion = {}

completion.split_input = function(input)
  -- TODO: Should handle luado, luaeval, v:lua
  local _, start = string.find(input, 'lua ')
  input = vim.trim(string.sub(input, start))

  -- TODO: Handle require
  --    1. handle the completion after the require
  --    2. handle the actual string completion part
  -- lua require('myplug.something').x

  -- TODO: Should handle each of the different ways to access tables:
  --        x["y"]
  --        x.y
  local split_input = vim.split(input, '.', true)

  return split_input
end

completion.possible_keys = function(input)
  local split_input = completion.split_input(input)
  local last_input = table.remove(split_input, #split_input)

  -- TODO: Questionable.... auto execute??
  -- TODO: Probably should be doing t his by wrapping them in quotes
  local val = loadstring("return " .. table.concat(split_input, '.'))()

  local prefix = 'lua ' .. table.concat(split_input, '.') .. '.'

  local results = {}
  for k, _ in pairs(val) do
    -- TODO: Only starting / fuzzy / etc.
    if string.find(k, last_input) then
      table.insert(results, prefix .. k)
    end
  end

  print(results)
end

completion.omnifunc = function(findstart, base)
end

completion.possible_keys("lua vim.tri")

return completion
