let s:binary_valid_tokens = 'bB0-1'
let s:hex_valid_tokens = 'xX#0-9a-fA-F'
let s:octal_valid_tokens = 'o0-7'

" General patterns for binary, hexadecimal, octal and decimal numbers
"
" start: Matches the start of a number
" end: Matches the end of a number
" tokens: Matches any of the valid tokens that can be found in the number
" valid: Matches a valid number
let s:patterns = {
    \'bin': {
        \'start': '0[bB]',
        \'end':  '[^' . s:binary_valid_tokens . ']',
        \'tokens':  '[' . s:binary_valid_tokens . ']',
        \'valid':  '^\(0[bB]\)[0-1]\+$',
    \},
    \'hex': {
        \'start': '0x\|0X\|#',
        \'end': '[^' . s:hex_valid_tokens . ']',
        \'tokens': '[' . s:hex_valid_tokens . ']',
        \'valid': '',
    },
    \'oct': {
    \},
    \'num': {
        \'start': '[^0-9.,\-+eE]',
        \'end': '[^0-9.,\-+eE]',
        \'tokens': '[0-9.,\-+eE]',
        \'valid': '^[\-+]\?[0-9]\+\(\.[0-9]\+\)\?\([eE][\-+]\?[0-9]\+\(\.[0-9]\+\)\?\)\?$',
    \},
\}

" let s:patterns.bin.end = ''
" let s:patterns.hex.end = ''
" let s:patterns.oct.end = ''

let s:number_types = ['binary', 'hexadecimal', 'octal', 'number']

" Set filetype-specific text objects
function! numbers#set_filetype_textobjects(ft) abort
    if !g:numbers#enable_text_objects
        return
    endif

    for number_type in s:number_types
        let b:numbers_buffer_language_funcs = {
            \'bin': function(printf('numbers#%s#vselect_binary', a:ft)),
            \'hex': function(printf('numbers#%s#vselect_hexadecimal', a:ft)),
            \'oct': function(printf('numbers#%s#vselect_octal', a:ft)),
            \'num': function(printf('numbers#%s#vselect_number', a:ft)),
        \}
    endfor
endfunction

" Merge language-specific patterns with the general patterns, keeping
" language-specific ones in case of duplication
function! numbers#merge_patterns(patterns) abort
    for number_type in s:number_types
        let key = number_type[:2]

        if !has_key(a:patterns, key) || !has_key(s:patterns, key)
            echoerr 'vim-numbers: Key not found'
        endif

        call extend(a:patterns[key], s:patterns[key], 'keep')
    endfor
endfunction

" Check if any language-specific, buffer-local, visual/operator mappings are in effect
function! numbers#has_buffer_language_mapping() abort
    let buffer_local_mapping = 'VselectLanguageBinaryNumber'

    return !empty(maparg(buffer_local_mapping, 'v')) && !empty(maparg(buffer_local_mapping, 'o'))
endfunction

function! numbers#execute_buffer_language_func(base) abort
    if exists('b:numbers_buffer_language_funcs')
        if has_key(b:numbers_buffer_language_funcs, a:base)
            return b:numbers_buffer_language_funcs[a:base]()
        endif
    endif

    return 0
endfunction

function! numbers#find_pattern_start_column(pattern, lnum) abort
    return searchpos(a:pattern, 'bcn', a:lnum)[1]
endfunction

function! numbers#find_pattern_end_column(pattern, lnum) abort
    let end_col = searchpos(a:pattern, 'cn', a:lnum)[1]

    if end_col == 0
        let end_col = col('$') - 1
    else
        let end_col -= 1
    endif

    return end_col
endfunction

" Visually select a pattern
function! numbers#vselect_pattern(patterns, offset) abort
    let [lnum, col] = getpos('.')[1:2]
    let line = getline(lnum)
    echom "line" line line[col-1]

    if line[col-1] !~# a:patterns.tokens
        return 0
    endif

    let start = numbers#find_pattern_start_column(a:patterns.start, lnum)
    echom "start" start

    if start == 0
        return 0
    endif

    let start += a:offset
    let end = numbers#find_pattern_end_column(a:patterns.end, lnum)
    let subline = line[start-1:end-1]

    echom start end subline

    if match(subline, a:patterns.valid) == -1
        return 0
    endif

    echom "valid"

    call numbers#vselect(lnum, start, end)

    return 1
endfunction

" Visually select an area specified by line number, start and end column
function! numbers#vselect(lnum, start_col, end_col) abort
    call cursor(a:lnum, a:start_col)
    normal! v
    call cursor(a:lnum, a:end_col)
endfunction
