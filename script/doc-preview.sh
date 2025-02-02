#!/bin/bash
#
USAGE=$(cat <<-END
	  $0   <file>
	  $0   <file:line>
	  $0   num-of-context  <file:line>
END
)

unset fnameline
unset fname
unset fline
unset fpos
unset nctx

# @args:nctx
if [ -z ${1} ]; then
    echo "${USAGE}"
    exit 1
else
    # is number
    if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
        nctx=$1
    else
        nctx=5
        fnameline=$1
    fi

    shift
fi

# @args:fname
if [ ! -v 'fnameline' ]; then
    if [ -z ${1} ]; then
        echo "${USAGE}"
        exit 1
    else
        fnameline=$1
        shift
    fi
fi

items=$(echo $fnameline | tr ":" "\n")

for item in $items
do
    if [ ! -v fname ]; then
        fname=$item
    elif [ ! -v fline ]; then
        fline=$item
    fi
done


if [ -v fline ]; then
    fpos=$((fline-nctx))
    fpos_end=$((fline+nctx))
    foffset=$((fpos_end-fpos))
    # echo ${fname}
    # echo ${fline}
    # echo "done"

    sed -n "${fpos},+${foffset}p" $fname
else
    head $fname
fi

