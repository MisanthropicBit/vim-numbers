" C++:
"   * Supports type suffixes, e.g. 18446744073709550592ull
"   * Supports "'" as separator, e.g. 18'446'744'073'709'550'592llu;

" See https://en.cppreference.com/w/cpp/language/integer_literal

let s:cpp_separator = "'"
let s:cpp_suffix_pattern = '\v(l|L|ll|LL|ull|ULL|uLL|llu|LLU|llU|LLu)'
let s:cpp_suffixes = [
    \'u',
    \'U',
    \'l',
    \'L',
    \'ll',
    \'LL',
    \'lu',
    \'LU',
    \'z',
    \'Z',
\]

let s:cpp_patterns = {}
call numbers#merge_patterns(s:cpp_patterns)

function! numbers#cpp#vselect_binary() abort
    return numbers#vselect_binary_number(s:cpp_patterns.bin, 0)
endfunction

function! numbers#cpp#vselect_hexadecimal() abort
    return numbers#vselect_hexadecimal_number(s:cpp_patterns.hex, 0)
endfunction

function! numbers#cpp#vselect_octal() abort
    return numbers#vselect_octal_number(s:cpp_patterns.oct, 0)
endfunction

function! numbers#cpp#vselect_number() abort
    return numbers#vselect_pattern(s:cpp_patterns.num, 0)
endfunction

vnoremap <silent> <Plug>(VselectCppBinaryNumber)      :<c-u>call numbers#cpp#vselect_binary()<cr>
onoremap <silent> <Plug>(VselectCppBinaryNumber)      :<c-u>call numbers#cpp#vselect_binary()<cr>
vnoremap <silent> <Plug>(VselectCppHexadecimalNumber) :<c-u>call numbers#cpp#vselect_hexadecimal()<cr>
onoremap <silent> <Plug>(VselectCppHexadecimalNumber) :<c-u>call numbers#cpp#vselect_hexadecimal()<cr>
vnoremap <silent> <Plug>(VselectCppOctalNumber)       :<c-u>call numbers#cpp#vselect_octal()<cr>
onoremap <silent> <Plug>(VselectCppOctalNumber)       :<c-u>call numbers#cpp#vselect_octal()<cr>
vnoremap <silent> <Plug>(VselectCppNumber)            :<c-u>call numbers#cpp#vselect_number()<cr>
onoremap <silent> <Plug>(VselectCppNumber)            :<c-u>call numbers#cpp#vselect_number()<cr>
