" autocmd BufRead,BufNewFile * :call numbers#set_filetype_textobjects()<cr>

" Set language-specific text objects when 'filetype' option has been set
autocmd FileType python :call numbers#set_filetype_textobjects('python')

" Set language-specific text objects when 'filetype' option has been set
" autocmd OptionSet filetype call numbers#set_filetype_textobjects(v:option_new)
