# zsh completion for `me`
# Source: source completions/zsh.sh

_me() {
    local -a results
    if [[ $CURRENT -eq 2 ]]; then
        results=("${(@f)$(me __commands)}")
    else
        local subcmd="${words[*]:1:CURRENT-1}"
        subcmd="${subcmd// /-}"
        results=("${(@f)$(me __complete "$subcmd")}")
    fi
    _describe values results
}
compdef _me me
