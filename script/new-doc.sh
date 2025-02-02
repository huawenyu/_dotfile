#!/bin/bash - 
set -o nounset                              # Treat unset variables as an error

declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source $DIR/conf/lib_log4sh.sh

# change the default message level from ERROR to INFO
#logger_setLevel INFO

# say hello to the world
logger_info "Create doc!"

Help ()
{
cat << EOF
Usage: please give mantis number

Samples:
  ${0##*/} 123456

EOF
exit ${1:-0}
}

if [ $# -eq 0 ]; then
    Help >&2
fi

mantis=$1
curDir=$(pwd)
realdocName="${mantis}-$(basename $curDir)"
softdocDir="doc"
realPDir="$HOME/work-doc"
if [ ! -d "$softdocDir" ]; then
    eval "mkdir -p ${realPDir}/${realdocName}"
    eval "ln -s ${realPDir}/${realdocName} ${softdocDir}"
    cd ${softdocDir}
    echo "mantis ${mantis} : " > README.md
else
    cd ${softdocDir}
fi

vi README.md

