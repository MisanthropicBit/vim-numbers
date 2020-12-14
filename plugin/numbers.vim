if &cp || exists('g:numbers_loaded')
    finish
endif

let s:cpo_save = &cpo

let s:vim_numbers_version = '0.1.0'

" Return the current version
function! VimNumbersVersion() abort
    return s:vim_numbers_version
endfunction

" Create a thousand separator pattern from a set of parameters
function! s:CreateThousandSeparatorPattern(base_pattern, name, tsep, dsep) abort
    let pattern = printf(a:base_pattern, a:tsep, a:dsep)
    execute printf("let s:number_thousand_separator_%s_pattern = '%s'", a:name, pattern)
endfunction

let s:binary_valid_tokens = 'bB0-1'
let s:hex_valid_tokens = 'xX#0-9a-fA-F'
let s:octal_valid_tokens = 'o0-7'

" Useful patterns
let s:leading_zeroes_pattern = '^[\-+]\?0\{2,}[0-9]\+'
let s:not_valid_number_tokens_pattern = '[^0-9.,\-+eE]'
let s:number_pattern = '^[\-+]\?[0-9]\+\(\.[0-9]\+\)\?\([eE][\-+]\?[0-9]\+\(\.[0-9]\+\)\?\)\?$'
let s:number_thousand_separator_base_pattern = '^[\-+]\?[0-9]\(\(%s[0-9]\{3}\)\+\)\(%s[0-9]\+\)\?$'

call s:CreateThousandSeparatorPattern(s:number_thousand_separator_base_pattern, 'dot', '\.', ',')
call s:CreateThousandSeparatorPattern(s:number_thousand_separator_base_pattern, 'comma', ',', '\.')

let s:binary_start_pattern = '0[bB]'
let s:binary_valid_token = '[' . s:binary_valid_tokens . ']'
let s:binary_end_pattern = '[^' . s:binary_valid_tokens . ']'
let s:binary_valid_pattern = '^\(' . s:binary_start_pattern . '\)[0-1]\+$'

let s:hex_start_pattern = '0x\|0X\|#'
let s:hex_valid_token = '[' . s:hex_valid_tokens . ']'
let s:hex_end_pattern = '[^' . s:hex_valid_tokens . ']'
let s:hex_valid_pattern = '^\(' . s:hex_start_pattern . '\)[0-9a-fA-F]\+$'

let s:octal_start_pattern = '[^0o0-7]'
let s:octal_valid_token = '[' . s:octal_valid_tokens . ']'
let s:octal_end_pattern = '[^' . s:octal_valid_tokens . ']'
let s:octal_valid_pattern = '^0o\?[0-7]\+$'

" Configuration variables
let g:numbers#include_leading_zeroes = get(g:, 'numbers#include_leading_zeroes', 1)
let g:numbers#enable_text_objects = get(g:, 'numbers#enable_text_objects', 1)

" Find the start column of a pattern in a line
function! s:FindPatternStartColumn(pattern, lnum) abort
    return searchpos(a:pattern, 'bcn', a:lnum)[1]
endfunction

" Find the end column of a pattern in a line
function! s:FindPatternEndColumn(pattern, lnum) abort
    let end_col = searchpos(a:pattern, 'cn', a:lnum)[1]

    if end_col == 0
        let end_col = col('$') - 1
    else
        let end_col -= 1
    endif

    return end_col
endfunction

" Visually select and validate a pattern given by a start and end pattern
function! s:VselectPattern(start_pattern, end_pattern, valid_pattern, valid_token_pattern, start_offset) abort
    let [lnum, col] = getpos('.')[1:2]
    let line = getline(lnum)

    if line[col-1] !~# a:valid_token_pattern
        return
    endif

    let start = s:FindPatternStartColumn(a:start_pattern, lnum)

    if start == 0
        return
    endif

    let start += a:start_offset
    let end = s:FindPatternEndColumn(a:end_pattern, lnum)
    let subline = line[start-1:end-1]

    if match(subline, a:valid_pattern) == -1
        return
    endif

    call cursor(lnum, start)
    normal! v
    call cursor(lnum, end)
endfunction

" Visually select a binary number
function! s:VselectBinaryNumber() abort
    call s:VselectPattern(
        \s:binary_start_pattern,
        \s:binary_end_pattern,
        \s:binary_valid_pattern,
        \s:binary_valid_token,
        \0,
    \)
endfunction

" Visually select a hexadecimal number
function! s:VselectHexNumber() abort
    call s:VselectPattern(
        \s:hex_start_pattern,
        \s:hex_end_pattern,
        \s:hex_valid_pattern,
        \s:hex_valid_token,
        \0,
    \)
endfunction

" Visually select an octal number
function! s:VselectOctalNumber() abort
    " We use an offset of 1 to move the start position one character to the
    " right because octal numbers can contain the '0' prefix so 041407357
    " would be selected as '07357' if the cursor was anywhere on the last five
    " characters of the octal number
    call s:VselectPattern(
        \s:octal_start_pattern,
        \s:octal_end_pattern,
        \s:octal_valid_pattern,
        \s:octal_valid_token,
        \1,
    \)
endfunction

" Find the start of a number
function! s:FindNumberStart(line, lnum) abort
    let start_col = searchpos(s:not_valid_number_tokens_pattern, 'bcn', a:lnum)[1]

    if start_col == 0
        let start_col = 1
    else
        " We found a valid first character that is not part of a number,
        " adjust column position to first character that is part of the number
        let start_col += 1
    endif

    " If leading zeroes are disabled, 0.239823 or -0.239823 is fine but 000.23943 is not
    if a:line[start_col-1:] =~# s:leading_zeroes_pattern && !g:numbers#include_leading_zeroes
        return 0
    endif

    return start_col
endfunction

" Find the end of a number
function! s:FindNumberEnd(lnum) abort
    let end_col = searchpos(s:not_valid_number_tokens_pattern, 'cn', a:lnum)[1]

    if end_col == 0
        let end_col = col('$') - 1
    else
        let end_col -= 1
    endif

    return end_col
endfunction

" Return 1 if a string is a valid number, 0 otherwise
function! s:IsValidNumber(string) abort
    " Match the number pattern or either of the patterns with thousand
    " separators
    if match(a:string, s:number_pattern) != -1
        \|| match(a:string, s:number_thousand_separator_dot_pattern) != -1
        \|| match(a:string, s:number_thousand_separator_comma_pattern) != -1
            " Do not consider valid octal numbers decimal numbers
            return match(a:string, '^0\d\+$') == -1
    endif

    return 0
endfunction

" Visually select a number
function! s:VselectNumber() abort
    let [lnum, col] = getpos('.')[1:2]
    let line = getline(lnum)

    if line[col-1] =~# s:not_valid_number_tokens_pattern
        return
    endif

    let start_col = s:FindNumberStart(line, lnum)

    if start_col == 0
        return
    endif

    let end_col = s:FindNumberEnd(lnum)
    let subline = line[start_col-1:end_col-1]

    if !s:IsValidNumber(subline)
        return
    endif

    call cursor(lnum, start_col)
    normal! v
    call cursor(lnum, end_col)
endfunction

" <Plug> mappings
vnoremap <silent> <Plug>(VselectNumber)         :<c-u>call <SID>VselectNumber()<cr>
onoremap <silent> <Plug>(VselectNumber)         :<c-u>call <SID>VselectNumber()<cr>
vnoremap <silent> <Plug>(VselectBinaryNumber)   :<c-u>call <SID>VselectBinaryNumber()<cr>
onoremap <silent> <Plug>(VselectBinaryNumber)   :<c-u>call <SID>VselectBinaryNumber()<cr>
vnoremap <silent> <Plug>(VselectHexNumber)      :<c-u>call <SID>VselectHexNumber()<cr>
onoremap <silent> <Plug>(VselectHexNumber)      :<c-u>call <SID>VselectHexNumber()<cr>
vnoremap <silent> <Plug>(VselectOctalNumber)    :<c-u>call <SID>VselectOctalNumber()<cr>
onoremap <silent> <Plug>(VselectOctalNumber)    :<c-u>call <SID>VselectOctalNumber()<cr>

if g:numbers#enable_text_objects
    vmap <silent> an <Plug>(VselectNumber)
    omap <silent> an <Plug>(VselectNumber)
    vmap <silent> in <Plug>(VselectNumber)
    omap <silent> in <Plug>(VselectNumber)
    vmap <silent> ax <Plug>(VselectHexNumber)
    omap <silent> ax <Plug>(VselectHexNumber)
    vmap <silent> ix <Plug>(VselectHexNumber)
    omap <silent> ix <Plug>(VselectHexNumber)
    vmap <silent> ai <Plug>(VselectBinaryNumber)
    omap <silent> ai <Plug>(VselectBinaryNumber)
    vmap <silent> ii <Plug>(VselectBinaryNumber)
    omap <silent> ii <Plug>(VselectBinaryNumber)
    vmap <silent> ao <Plug>(VselectOctalNumber)
    omap <silent> ao <Plug>(VselectOctalNumber)
    vmap <silent> io <Plug>(VselectOctalNumber)
    omap <silent> io <Plug>(VselectOctalNumber)
endif

let g:numbers_loaded = 1
let &cpo = s:cpo_save
