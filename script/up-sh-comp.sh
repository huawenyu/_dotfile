#!/bin/bash
#set -o nounset     # Treat unset variables as an error
# Current only works under bash/zsh

declare -r DIR=$(cd "$(dirname "$0")" && pwd)

if ! command -v compleat &> /dev/null; then
    echo "Can't find 'compleat', please add '$DIR' to the current env: $PATH"
    exit
fi
compDIR=$(which compleat)
compDIR=$(dirname $compDIR)
traceDIR=$(which traceme)
traceDIR=$(dirname $traceDIR)

if echo "$SHELL" | grep -q "zsh"; then
    mkdir -p ~/.local
    shellRC=~/.local/local
elif echo "$SHELL" | grep -q "bash"; then
    shellRC=~/.bashrc
else
    echo "Don't support '$SHELL', prefer bash/zsh!"
    exit 1
fi

if grep -q "compleat_setup" $shellRC; then
    echo "Compleat was ready $shellRC, no need install again!"
    echo "  Enjoy $compDIR/<cmds>.usage"
else
    echo "source $DIR/conf/compleat_setup" >> $shellRC
    echo "export TracemeDIR=$traceDIR/../config/trace.d" >> $shellRC
    echo "Install compleat_setup succ, please load '$shellRC' again!"
    echo "  Enjoy $compDIR/<cmds>.usage"
fi

