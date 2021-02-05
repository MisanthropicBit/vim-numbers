" Python:
"   * Supports both '78.' and '78.0'
"   * '_' as separator (see PEP 515: https://www.python.org/dev/peps/pep-0515/)
"   * Supports scientific notation and 2**4 syntax. The latter is allowed with
"     binary, hexadecimal, and octal numbers.

let s:python_separator = '_'

let s:python_bin_tokens = '[bB01_]'
let s:python_bin_end = '[^' . s:python_bin_tokens[1:-2] . ']'
let s:python_bin_valid = '^0[bB][01_]\+$'

let s:python_hex_start = '0[xX]'
let s:python_hex_tokens = '[xX0-9a-fA-F_]'
let s:python_hex_end = '[^' . s:python_hex_tokens[1:-2] . ']'
let s:python_hex_valid = '^\(' . s:python_hex_start . '\)[0-9a-fA-F_]\+$'

let s:python_oct_tokens = '[oO0-7_]'
let s:python_oct_end = '[^' . s:python_oct_tokens[1:-2] . ']'
let s:python_oct_valid = '^0[oO][0-7_]\+$'

let s:python_number_valid = '^[\-+]\?[0-9]\+\(\.\([0-9]\+\)\?\)\?\([eE][\-+]\?[0-9]\+\(\.[0-9]\+\)\?\)\?$'

let s:python_patterns = {
    \'bin': {
        \'end': s:python_bin_end,
        \'tokens': s:python_bin_tokens,
        \'valid': s:python_bin_valid,
    \},
    \'hex': {
        \'start': s:python_hex_start,
        \'end': s:python_hex_end,
        \'tokens': s:python_hex_tokens,
        \'valid': s:python_hex_valid,
    \},
    \'oct': {
        \'end': s:python_oct_end,
        \'tokens': s:python_oct_tokens,
        \'valid': s:python_oct_valid,
    \},
    \'num': {
        \'valid': s:python_number_valid,
    \},
\}

call numbers#merge_patterns(s:python_patterns)

function! numbers#python#vselect_binary() abort
    return numbers#vselect_pattern(s:python_patterns.bin, 0)
endfunction

function! numbers#python#vselect_hexadecimal() abort
    return numbers#vselect_pattern(s:python_patterns.hex, 0)
endfunction

function! numbers#python#vselect_octal() abort
    return numbers#vselect_pattern(s:python_patterns.oct, 0)
endfunction

function! numbers#python#vselect_number() abort
    return numbers#vselect_pattern(s:python_patterns.num, 0)

    " let [selection, lnum, start_col, end_col] = numbers#number_bounds()

    " if numbers#validate_number(selection, s:python_number_valid)
    "     call numbers#vselect(lnum, start_col, end_col)
    " endif
endfunction

vnoremap <silent> <Plug>(VselectPythonBinaryNumber)      :<c-u>call numbers#python#vselect_binary()<cr>
onoremap <silent> <Plug>(VselectPythonBinaryNumber)      :<c-u>call numbers#python#vselect_binary()<cr>
vnoremap <silent> <Plug>(VselectPythonHexadecimalNumber) :<c-u>call numbers#python#vselect_hexadecimal()<cr>
onoremap <silent> <Plug>(VselectPythonHexadecimalNumber) :<c-u>call numbers#python#vselect_hexadecimal()<cr>
vnoremap <silent> <Plug>(VselectPythonOctalNumber)       :<c-u>call numbers#python#vselect_octal()<cr>
onoremap <silent> <Plug>(VselectPythonOctalNumber)       :<c-u>call numbers#python#vselect_octal()<cr>
vnoremap <silent> <Plug>(VselectPythonNumber)            :<c-u>call numbers#python#vselect_number()<cr>
onoremap <silent> <Plug>(VselectPythonNumber)            :<c-u>call numbers#python#vselect_number()<cr>
