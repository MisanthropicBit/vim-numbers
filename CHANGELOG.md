# 1.0.3

* Fix number vselect contexts
  - Recognise comma-separated numbers with scientific notation
  - Add tests for context cases (e.g. lists and dictionaries)
  - Add 2 new failing tests that fail due to ambiguity
  - Add test for leading zeroes

# 1.0.2

* Fix a bug in selecting octal numbers at the beginning of lines. Also make
  selecting octal numbers with multiple valid prefixes, e.g. `041407357` more
  robust.
* Update documentation with `0O` as a valid octal prefix.
* Fix covimerage bug with click 8.0.1 in GitHub Actions workflow.
* New logo!

# 1.0.1

* Select octal numbers prefixed with a zero and capital o: '0O'

# 1.0.0

* GitHub Actions test workflow with [code
  coverage](https://coveralls.io/github/MisanthropicBit/vim-numbers) via
  [covimerage](https://github.com/Vimjas/covimerage).
* Text objects also works for numbers with thousand separators such as
  currencies.
* Added issue and pull request templates.

# 0.1.0

* Initial pre-release version.
