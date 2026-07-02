#!/usr/bin/env bash
# Shared library for `me` subcommands
# Usage from subcommand script:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/me-lib.sh"
#   me_init "$@"

me_init() {
    var_ScriptDir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")" &>/dev/null && pwd)"
    var_ScriptName="$(basename "$0")"
    var_ScriptName="${var_ScriptName%.*}"
    var_WorkDir="$(pwd)"
    SECONDS=0
    me_red='\e[31m'; me_green='\e[32m'; me_yellow='\e[33m'; me_cyan='\e[36m'; me_reset='\e[0m'
    me_handle_api "$@"
}

me_handle_api() {
    case "${1:-}" in
        --summary) echo "$ME_SUMMARY"; exit 0 ;;
        --complete|__complete) printf '%s\n' $ME_COMPLETE; exit 0 ;;
        -h|--help) var_RequestHelp=1 ;;
    esac
}

me_check_debug() {
    if [[ -n "${var_DRYRUN:-}" ]]; then
        (set -o posix; set) | grep -e '^var_'
        exit 1
    fi
    [[ "${var_VERBOSE:-0}" -ge 3 ]] && set -x
    [[ "${var_VERBOSE:-0}" -ge 4 ]] && set -v
}

me_dispatch_getoptions() {
    local parser="${1:-parse_define}"
    shift 2>/dev/null || true
    if command -v getoptions &>/dev/null; then
        eval "$(getoptions "$parser") exit 1"
        # REST is set by getoptions; propagate to caller's positional params
        var_REST="${REST:-}"
        if [ "${var_RequestHelp:-0}" = "1" ]; then
            (eval "getoptions_parse -h --help") 2>&1
            echo ""
            echo "Script: $(readlink -f "$0")"
            exit 0
        fi
    else
        cat >&2 <<'EOF'
Error: getoptions not found. Install:
  wget -O $HOME/bin/getoptions https://github.com/ko1nksm/getoptions/releases/latest/download/getoptions
EOF
        exit 1
    fi
}

cleanup() {
    trap - EXIT
    local duration=$SECONDS
    echo "cleanup(${var_Action:-none} time=$((duration/60))m:$((duration%60))s)" >&2
    local td; for td in TEMPFILE TEMPFILE2; do
        [[ -n "${!td:-}" ]] && rm -f "${!td}" 2>/dev/null
    done
    cd "$var_WorkDir" 2>/dev/null || true
}

die() {
    echo -e "${me_red}${var_ScriptName}: $*${me_reset}" >&2
    cleanup
    exit 1
}

trap "cleanup; exit 130" 1 2 3 15
