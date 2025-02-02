#!/bin/bash
set -xv

if [ "$#" -eq 2 ]; then
    if [ "$1" == "function" ]; then
        awk '
        ($2 == "function" && $1~/.*'$2'.*/) {
            printf $4":"$3":";

            for(i=5;i<=NF;i++)
            {
                if(i== NF)
                    printf "%s", $i;
                else
                    printf "%s ", $i;
            }

            printf "\n"
        }' tags.x > /tmp/vim.taglist
    else
        awk '
        ($2 != "function" && $1~/.*'$2'.*/) {
            printf $4":"$3":";

            for(i=5;i<=NF;i++)
            {
                if(i== NF)
                    printf "%s", $i;
                else
                    printf "%s ", $i;
            }

            printf "\n"
        }' tags.x > /tmp/vim.taglist
    fi
elif [ "$#" -eq 3 ]; then
    if [ "$1" == "function" ]; then
        awk '
        ($2 == "function" && $1~/.*'$2'.*/ && $4~/.*'$3'.*/) {
            printf $4":"$3":";

            for(i=5;i<=NF;i++)
            {
                if(i== NF)
                    printf "%s", $i;
                else
                    printf "%s ", $i;
            };

            printf "\n"
        }' tags.x > /tmp/vim.taglist
    else
        awk '
        ($2 != "function" && $1~/.*'$2'.*/ && $4~/.*'$3'.*/) {
            printf $4":"$3":";

            for(i=5;i<=NF;i++)
            {
                if(i== NF)
                    printf "%s", $i;
                else
                    printf "%s ", $i;
            }

            printf "\n"
        }' tags.x > /tmp/vim.taglist
    fi
fi

