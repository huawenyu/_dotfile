#!/bin/bash
#
# Usage: self <pid> [0/1 - Print 0 or 1]
#read -p "PID=" pid
#
if [ "$#" -eq 0 ]; then
    echo "Usage: self [1/0] <pid>"
elif [ "$#" -eq 1 ]; then
    bitShow=1
    pid=$1
else
    bitShow=$1
    pid=$2
fi


cat /proc/$pid/status|egrep '(Sig|Shd)(Pnd|Blk|Ign|Cgt)' | while read name mask; do
    bin=$(echo "ibase=16; obase=2; ${mask^^*}"|bc)
    echo -n "$name $mask $bin "
    i=1
    while [[ $bin -ne 0 ]];do
        if [[ ${bin:(-1)} -eq $bitShow ]]; then
            #echo "$i=${bin:(-1)}"
            if [[ $i -lt 34 ]]; then
                { echo "$i-"; kill -l $i; } | tr '\n' ' '
            fi
        fi

        bin=${bin::-1}
        set $((i++))
    done
    echo
done
# vim:et:sw=4:ts=4:sts=4:
