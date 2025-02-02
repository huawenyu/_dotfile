#!/usr/bin/env bash
# Ref: https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:
  -h, --help      Print this help and exit
  -v, --verbose   Print script debug info
  -f, --flag      Some flag description
  -p, --param     Some param description
EOF
  exit
}

trap cleanup SIGINT SIGTERM RETURN ERR EXIT
cleanup() {
	trap - SIGINT SIGTERM RETURN ERR EXIT
	# script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) flag=1 ;; # example flag
    -p | --param) # example named parameter
      param="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ -z "${param-}" ]] && die "Missing required parameter: param"
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"
setup_colors

# script logic here

msg "${RED}Read parameters:${NOFORMAT}"
msg "- flag: ${flag}"
msg "- param: ${param}"
msg "- arguments: ${args[*]-}"
return 0






# Sample - 2
#!/bin/bash
# What need change? {{{1
#   - Help()
#   - GetOpts()
#   - Main()    our script here
#
declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source $DIR/lib_common.sh

# header {{{1
#   sample.sh -- script template
NOTE="a script template"
_DEBUG="off"
verbose=0
dryrun="off"

# functions {{{1
# help {{{2
Help ()
{
cat << EOF
Usage: ${0##*/} [-hvdn] [-m <message>]

Options:
  -h  help
  -v  verbose
  -d  debug
  -n  dry-run

Samples:
  ./${0##*/} -dn -m "hello"

EOF
exit ${1:-0}
}

# basic function {{{2
GetOpts ()
{
    if [ $# -eq 0 ]; then
        Help >&2
    fi

    # Reset is necessary if getopts was used previously in the script.
    OPTIND=1
    local opt
    while getopts "hvdnm:" opt; do
    case "$opt" in
    h)
        Help
        ;;
    v)  verbose=$OPTARG
        ;;
    d)  _DEBUG="on"
        ;;
    n)  dryrun="on"
        ;;
    m)  usermsg=$OPTARG
        ;;
    \?)
        Help >&2
        ;;
    *)
        Help >&2
        ;;
    esac
    done
    # Shift off the options and optional
    shift "$((OPTIND-1))"

    # Check options
    if [ -z "${usermsg}" ] || [ -z "${verbose}" ]; then
        Help
    fi
}

DEBUG() { [ "$_DEBUG" == "on" ] && $@; }
Echo () { echo "# $(basename $0): $*"; }
Die()   { echo $1; exit 1; }

Run ()
{
    if [ "$dryrun" == "off" ]; then
        eval "$@"
    else
        echo "Will $*"
        return 0
    fi
}

# user function {{{2

Demo()
{
    DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"

    Run "ls"
    Run ls -l

    DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
}

# Main: user script {{{1
Main ()
{
    DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
    printf "$NOTE: dry=$dryrun v=$verbose\n"
    ################################################

    # Put our script here {{{2
    Demo

    ################################################
    DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
}

# footer {{{1
old_dir=$(pwd) 2> /dev/null
DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
GetOpts "$@"
DEBUG set -vx
Main "$@"
DEBUG set +vx
DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]}{{{${#FUNCNAME[@]}\n"
cd $old_dir
# End of file

