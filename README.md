<div align="center">
  <br />
  <img width="80%" src="vim-numbers-logo.svg" />
  <p><i>Text objects for numbers</i></p>
  <p>
    <img src="https://img.shields.io/badge/version-1.0.3-blue" />
    <a href="https://github.com/MisanthropicBit/vim-numbers/actions?query=workflow%3A%22Run+vader+tests%22">
        <img src="https://img.shields.io/github/workflow/status/MisanthropicBit/vim-numbers/Run%20vader%20tests/master" />
    </a>
    <a href="https://coveralls.io/github/MisanthropicBit/vim-numbers?branch=master">
        <img src="https://coveralls.io/repos/github/MisanthropicBit/vim-numbers/badge.svg?branch=master" alt="Coverage Status" />
    </a>
    <a href="/LICENSE">
        <img src="https://img.shields.io/github/license/MisanthropicBit/vim-numbers" />
    </a>
    <img src="https://img.shields.io/badge/compatible-neovim-blueviolet" />
  </p>
  <br />
</div>

A small plugin that provides text objects for numbers.

* Typing `van` or `vin` selects an integral or floating-point number (optionally
  with scientific notation and/or thousand separators).
* Typing `vai` or `vii` selects a binary number (prefixed by `0b` or `0B`).
* Typing `vax` or `vix` selects a hexadecimal number (prefixed by `0x`, `0X`, or `#`).
* Typing `vao` or `vio` selects an octal number (prefixed by `0`, `0o`, or `0O`).

There is no difference in selecting "a number" or "inner number".

![vim-numbers demo](vim-numbers-demo.gif)

(*Demo uses [keycastr](https://github.com/keycastr/keycastr) and Mac's
[Cmd+Shift+5](https://support.apple.com/en-us/HT208721)*)

## Installation

* [Pathogen](https://github.com/tpope/vim-pathogen):
  `git clone https://github.com/MisanthropicBit/vim-numbers ~/.vim/bundle/vim-numbers`
* [NeoBundle](https://github.com/Shougo/neobundle.vim):
  `NeoBundle 'MisanthropicBit/vim-numbers'`
* [VAM](https://github.com/MarcWeber/vim-addon-manager):
  `call vam#ActivateAddons(['MisanthropicBit/vim-numbers'])`
* [Vundle](https://github.com/VundleVim/Vundle.vim):
  `Plugin 'MisanthropicBit/vim-numbers'`
* [vim-plug](https://github.com/junegunn/vim-plug):
  `Plug 'MisanthropicBit/vim-numbers'`

## Similar Projects

* [tkhren/vim-textobj-numeral](https://github.com/tkhren/vim-textobj-numeral)
