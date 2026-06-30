# bash completion for `me`
# Source: source completions/bash.sh

_me() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$(me __commands)" -- "$cur"))
    else
        local subcmd="${COMP_WORDS[*]:1:COMP_CWORD-1}"
        subcmd="${subcmd// /-}"
        COMPREPLY=($(compgen -W "$(me __complete "$subcmd")" -- "$cur"))
    fi
}
complete -F _me me
