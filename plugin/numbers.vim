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
let s:number_pattern_dot =   '\v^[-+]?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+(\.[0-9]+)?)?$'
let s:number_pattern_comma = '\v^[-+]?[0-9]+(,[0-9]+)?([eE][-+]?[0-9]+(\.[0-9]+)?)?$'
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

" Find the start of a number
function! FindNumberStart(valid_tokens, line) abort
    let col = col('.') - 1
    let start_col = col
    let chr = a:line[col]

    " Fail if the first character is not a valid token or a number,
    " or it is a sign token and preceded by a number (e.g. '1+200')
    if chr =~# '[+-]' && a:line[col-1] =~# '[0-9]'
        return -1
    endif

    while col >= 0
        if chr !~# '[0-9]'
            let prev = a:line[col-1]

            " If the character is a + or -, check that the previous
            " character is a number or an 'e' for the exponent
            if chr =~# '[+-]'
                if prev !~# '[eE]'
                    if prev !~# '[0-9]'
                        break
                    else
                        " Previous character is a number, assume that the
                        " operation is part of a calculation, e.g. '1+2',
                        " and move to last valid character instead
                        let col += 1
                        break
                    endif
                endif
            elseif chr =~# a:valid_tokens
                if prev !~# '[0-9]'
                    " A valid token must be preceded by a number, go back to
                    " the last valid character
                    let col += 1
                    break
                endif
            else
                " Not a number or valid token, move to last valid character
                let col += 1
                break
            endif
        endif

        let col -= 1
        let chr = a:line[col]
    endwhile

    return min([start_col, col == -1 ? 0 : col])
endfunction

" Find the end of a number
function! FindNumberEnd(valid_tokens, line) abort
    let col = col('.') - 1
    let start_col = col
    let number_seen = 0

    while col < col('$')
        let chr = a:line[col]

        if chr !~# '[0-9]'
            let next = a:line[col + 1]

            if chr =~# '[eE]'
                " An exponent must be followed by a sign or a number
                if next !~# '[+\-0-9]'
                    break
                endif
            elseif chr =~# '[+-]'
                if next !~# '[0-9]'
                    let col -= 1
                    break
                else
                    " If the next character is a number which is not preceded
                    " by an exponent token and we have already seen a number,
                    " bail out
                    if a:line[col-1] !~# '[eE]'
                        if number_seen
                            let col -= 1
                            break
                        endif
                    endif
                endif
            elseif chr =~# a:valid_tokens
                if next !~# '[0-9]'
                    " A valid token must be followed by a number, go back to
                    " the last valid character
                    let col -= 1
                    break
                endif
            else
                let col -= 1
                break
            endif
        endif

        let col += 1
        let number_seen = 1
    endwhile

    return max([start_col, col])
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

" Return 1 if a string is a valid number, 0 otherwise
function! s:IsValidNumber(string) abort
    " Match the number pattern or either of the patterns with thousand
    " separators
    if match(a:string, s:number_pattern_dot) != -1
        \|| match(a:string, s:number_pattern_comma) != -1
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

    let start_col = FindNumberStart('[+-,.eE]', line)

    if start_col == -1
        return
    endif

    let end_col = FindNumberEnd('[+-,.eE]', line)
    let subline = line[start_col:end_col]

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
