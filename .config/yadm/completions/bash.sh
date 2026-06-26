_bootstrap() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$(bootstrap __commands)" -- "$cur"))
    else
        local cmd="${COMP_WORDS[1]}"
        COMPREPLY=($(compgen -W "$(bootstrap __complete "$cmd")" -- "$cur"))
    fi
}
complete -F _bootstrap bootstrap
