

nnoremap <silent> <Plug>(ConquerOpen) :lua require('conquer').make_command_window()<CR>

" If a use sets:
"
" let g:conquer_use_default_mappings = v:false
"
" Then we won't set the mappings. Otherwise we will
if get(g:, "conquer_use_default_mappings", v:true)
  nmap <space>: <Plug>(ConquerOpen)
endif
