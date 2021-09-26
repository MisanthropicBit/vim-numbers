if &cp || exists('g:numbers_loaded')
    finish
endif

let s:cpo_save = &cpo

let s:vim_numbers_version = '1.0.2'

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
let s:octal_valid_tokens = 'oO0-7'

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

let s:octal_start_pattern = '0[oO]\?[0-7]'
let s:octal_valid_token = '[' . s:octal_valid_tokens . ']'
let s:octal_end_pattern = '[^' . s:octal_valid_tokens . ']'
let s:octal_valid_pattern = '^0[oO]\?[0-7]\+$'

" Configuration variables
let g:numbers#include_leading_zeroes = get(g:, 'numbers#include_leading_zeroes', 1)
let g:numbers#enable_text_objects = get(g:, 'numbers#enable_text_objects', 1)

function! FindNumberStart2(valid_tokens, line) abort
    let col = col('.') - 1
    let chr = a:line[col]

    echom stridx(a:valid_tokens, a:line[col])
    echom match(a:line[col], '[0-9]')

    if chr !~# a:valid_tokens && chr !~# '[0-9]'
        return -1
    elseif chr =~# '[+-]' && a:line[col-1] =~# '[0-9]'
        return -1
    endif

    while col >= 0
        echom a:line[col] a:line[col - 1] match(chr, '[0-9]') stridx(a:valid_tokens, chr)

        if chr !~# '[0-9]'
            if chr =~# a:valid_tokens
                let prev = a:line[col-1]

                " If the character is a + or -, check that the previous
                " character is a number or an 'e' for the exponent
                if chr =~# '[+-]'
                    if prev !~# '[eE]'
                        if prev !~# '[0-9]'
                            break
                        else
                            " Previous character is not a number, assume that
                            " the addition or subtraction is part of a
                            " calculation, e.g. '1+2', and move to last valid
                            " character instead
                            let col += 1
                            break
                        endif
                    endif
                endif
            else
                let col += 1
                break
            endif
        endif

        let col -= 1
        let chr = a:line[col]
    endwhile

    return col == -1 ? 0 : col
endfunction

function! FindNumberEnd2(valid_tokens, line) abort
    let col = col('.') - 1
    echom col

    " Handle the case where the cursor is situated on a sign
    if a:line[col] =~# '[-+]' && a:line[col+1] !~# '[0-9]'
        return col
    else
        let col += 1
    endif

    while col < col('$')
        let chr = a:line[col]
        echom a:line[col] a:line[col + 1]

        if chr !~# '[0-9]'
            if chr =~# a:valid_tokens
                let next = a:line[col + 1]

                if chr =~# '[eE]'
                    " The exponent must be followed by a sign or a number
                    if next !~# '[+\-0-9]'
                        break
                    endif
                elseif chr =~# '[+-]'
                    if a:line[col-1] !~# '[eE]' || next !~# '[0-9]'
                        let col -= 1
                        break
                    endif
                elseif next !~# '[0-9]'
                    " A valid token must be followed by a number
                    let col -= 1
                    break
                endif
            else
                let col -= 1
                break
            endif
        endif

        let col += 1
    endwhile

    return col
endfunction

function! FindLastPatternMatch(pattern, token_pattern, lnum, dir) abort
    " Save the old cursor so we can restore it afterwards
    let old_cursor = getpos('.')[1:2]

    let search_flags = a:dir == 1 ? '' : 'b'

    " Search and move the cursor
    let col = searchpos(a:pattern, search_flags . 'c', a:lnum)[1]
    let end_col = a:dir == 1 ? col('$') - 1 : 1
    let final_col = col

    while col != end_col
        " Continue searching until we fail but do not accept matches at the
        " current cursor position to avoid matching at the current position
        let col = searchpos(a:pattern, search_flags, a:lnum)[1]

        if !match(getline(a:lnum)[col], a:token_pattern)
            let final_col = col
            break
        endif

        let final_col = col
    endwhile

    call cursor(old_cursor)

    return final_col
endfunction

" Find the start column of a pattern in a line
function! s:FindPatternStartColumn(pattern, lnum) abort
    return searchpos(a:pattern, 'bcn', a:lnum)[1]
endfunction

" We need to take special care of octal numbers since octal numbers can
" contain a valid '0' prefix so 041407357 would be selected as '07357' if the
" cursor was anywhere on the last five characters of the octal number
function! s:FindOctalStartColumn(pattern, lnum) abort
    " Save the old cursor so we can restore it afterwards
    let old_cursor = getpos('.')[1:2]

    " Search backwards and move the cursor
    let col = searchpos(a:pattern, 'bc', a:lnum)[1]
    let start_col = col

    while col != 0
        " Continue searching backwards until we fail but do
        " not accept matches at the current cursor position
        " to avoid matching at the current position
        let col = searchpos(a:pattern, 'b', a:lnum)[1]

        if col != 0
            let start_col = col
        endif
    endwhile

    call cursor(old_cursor)

    return start_col
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
function! s:VselectPattern(start_pattern, end_pattern, valid_pattern, valid_token_pattern) abort
    let [lnum, col] = getpos('.')[1:2]
    let line = getline(lnum)

    if line[col-1] !~# a:valid_token_pattern
        return
    endif

    if a:start_pattern ==# s:octal_start_pattern
        let start = s:FindOctalStartColumn(a:start_pattern, lnum)
    else
        let start = s:FindPatternStartColumn(a:start_pattern, lnum)
    endif

    if start == 0
        return
    endif

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
    \)
endfunction

" Visually select a hexadecimal number
function! s:VselectHexNumber() abort
    call s:VselectPattern(
        \s:hex_start_pattern,
        \s:hex_end_pattern,
        \s:hex_valid_pattern,
        \s:hex_valid_token,
    \)
endfunction

" Visually select an octal number
function! s:VselectOctalNumber() abort
    call s:VselectPattern(
        \s:octal_start_pattern,
        \s:octal_end_pattern,
        \s:octal_valid_pattern,
        \s:octal_valid_token,
    \)
endfunction

function! s:LeadingZeroesAllowed(str) abort
    " If leading zeroes are disabled, 0.239823 or -0.239823 is fine but
    " 000.23943 is not
    if a:str =~# s:leading_zeroes_pattern && !get(g:, 'numbers#include_leading_zeroes')
        return 0
    else
        return 1
    endif
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

    let start_col = FindNumberStart2('[,.+-eE]', line)
    echom 'start_col' start_col

    if start_col == -1
        return
    endif

    let end_col = FindNumberEnd2('[,.+-eE]', line)
    echom 'end_col' end_col
    let subline = line[start_col:end_col]
    echom 'subline' subline
    echom 'valid' s:IsValidNumber(subline)

    if !s:IsValidNumber(subline)
        return
    endif

    if !s:LeadingZeroesAllowed(subline)
        return
    endif

    call cursor(lnum, start_col + 1)
    normal! v
    call cursor(lnum, end_col + 1)
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
