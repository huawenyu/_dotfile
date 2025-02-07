#! /bin/bash
# vim: setlocal autoindent cindent et ts=4 sw=4 sts=4:
#

currDir=$(pwd)
varStart=$(date +%s)

_Usage=$(cat <<-END
    Usage: handle a files
      script [options] [file ...]

    Options:
      -v, -vvv, --verbose   Print all cmds if v<count> >= 3,
      -n, --dryrun          Dump variables if prefix-as 'var_'
      -d, --dir             the working dir
      -o, --out             the output filename, (default: /tmp/merged.md)
      -h, --help            Usage
      --version             Version

    Sample:
      bash -x script        ### Run the script with debug mode enabled.
      bash -n script        ### Check for syntax errors without execution.

      script <dir>


END
)

type getoptions 2>&1 > /dev/null || \
    (echo "Require 'getoptions': <===???"; \
    echo "Install getoptions (https://github.com/ko1nksm/getoptions)"; \
    echo "wget https://github.com/ko1nksm/getoptions/releases/latest/download/getoptions -O $HOME/bin/getoptions"; \
    echo ""; echo "$_Usage"; \
    exit 2;)

# Handle option {{{1}}}
function parser_definition() {
  setup   REST help:usage -- "Usage: git worktree2 [options] [branch-name] [dest-work-dir] ..." ''

  msg -- 'Options:'
  flag  var_VERBOSE    -v --verbose  counter:true init:=0    -- "e.g. -vvv is verbose level 3"
  flag  var_DRYRUN     -n --dryrun                           -- "Dryrun mode"
  param var_DIR        -d --dir      init:=""                -- "the working dir"
  param var_OUTPUT     -o --out      init:="/tmp/merged.md"  -- "the output filename"

  disp  VERSION        --version
  disp  :usage         -h --help   -- "$_Usage"
}

eval "$(getoptions parser_definition) exit 1"
var_RestArg="$@" # rest arguments


DoIt () {
    >&2 echo "    DO: $*"
    eval "$@"
}

main () {
    case "$#" in
        2)
            ;;
        1)
            if [ -z "$var_DIR" ]; then
                var_DIR="$1"
            fi
            ;;
        0)
            ;;
        *)
            echo "$_Usage"
            die "Arguments incorrect!"
            ;;
    esac


    if [[ -n "$var_DRYRUN" ]]; then
        ( set -o posix ; set ) | grep -e '^var_'
        exit 1
    fi

    if [[ "$var_VERBOSE" -ge 3 ]]; then
        set -x                              ### Print each command before eval
    fi

    if [[ "$var_VERBOSE" -ge 4 ]]; then
        set -v                              ### Print each line of the script before eval
    fi

    ### Normalize the args
    # set --                                ### Clears positional parameters
    # input="arg1 arg2 'arg with spaces'"   ### If arg have space
    # eval set -- $input
    do_task "$@"
}


do_task () {
    maketemp

    # Clear the output file
    > "$var_OUTPUT"

    # Dummy-Loop-once
    for i in $(seq 1); do
        if [[ ! -d "$var_DIR" ]]; then
            echo "Dir '$var_DIR' not exist, exit ..."
            break
        fi

        # Find all .md files, sort them, and process each one
        for file in $(find "$var_DIR" -type f -name "*.md" | sort); do
            sed 's/^#/##/'  "$file" > $TEMPFILE
            echo "# $(basename "$file" .md)" >> "$var_OUTPUT"   # Add header
            echo -e "\n" >> "$var_OUTPUT"                       # Add blank line
            cat "$file" >> "$var_OUTPUT"                        # Append content
            echo -e "\n\n" >> "$var_OUTPUT"                     # Add blank line
        done

        ## Create a standalone document with Pandoc
        #pandoc -s "$output_file" -o final.md

        echo "Merged document saved as $var_OUTPUT"

        # Sanity loop once
        break
    done
}

die () {
    [ "$#" -gt 0 ] && echo "$0: $@" >&2
    cleanup
    exit 1
}

TEMPFILE=

maketemp () {
    if [ -z "$TEMPFILE" ]; then
        TEMPFILE="$(mktemp /tmp/git-info.XXXXXX)" || die
        trap "cleanup; exit 130" 1 2 3 15
    fi

    if [ -z "$TEMPFILE2" ]; then
        TEMPFILE2="$(mktemp /tmp/git-info.XXXXXX)" || die
        trap "cleanup; exit 130" 1 2 3 15
    fi
}

trap cleanup EXIT INT TERM
function cleanup() {
    trap - EXIT

    varEnd=$(date +%s)
    echo "trap-cleanup(time=$(($varEnd - $varStart)))"

    if [ -n "$TEMPFILE" ]; then
        rm -f "$TEMPFILE" 2> /dev/null
    fi

    if [ -n "$TEMPFILE2" ]; then
        rm -f "$TEMPFILE2" 2> /dev/null
    fi

    # Backto the original current dir
    cd "$currDir"
}

main "$@"



