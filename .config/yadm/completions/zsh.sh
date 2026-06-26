_bootstrap() {
    local -a results
    if [[ $CURRENT -eq 2 ]]; then
        results=("${(@f)$(bootstrap __commands)}")
    else
        results=("${(@f)$(bootstrap __complete "${words[2]}")}")
    fi
    _describe values results
}
compdef _bootstrap bootstrap
