#!/usr/bin/env bash

if [ -f "$VADER_OUTPUT_FILE" ]; then
    # Remove the old vader.log file if it exists
    rm $VADER_OUTPUT_FILE
fi

TESTVIM_OPTS=

# Neovim is always "nocompatible"
if [ "$TESTVIM" = "vim" ]; then
  TESTVIM_OPTS=-N
fi

$TESTCMD $TESTVIM $TESTVIM_OPTS -u ./tests/test_vimrc -c 'Vader! ./tests/*.vader'

if [ -f "$VADER_OUTPUT_FILE" ]; then
    cat $VADER_OUTPUT_FILE
else
    echo "Warning: No vader output file found"
fi
