#!/usr/bin/env bash

TESTVIM_OPTS=

# Neovim is always "nocompatible"
if [ "$TESTVIM" = "vim" ]; then
  TESTVIM_OPTS=-N
fi

$TESTVIM $TESTVIM_OPTS -u ./tests/test_vimrc -c 'Vader! ./tests/*.vader' > /dev/null
