
# common function {{{2

# arr=(a b c "d e" f g)
# array_contains arr "a b"  && echo yes || echo no    # no
# array_contains arr "d e"  && echo yes || echo no    # yes
array_contains ()
{
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

# retval=$( call_ret_string "testfile" )
# if [ "$retval" == "true" ]; then
#      echo "result is true"
# else
#      echo "result is not true"
# fi
call_ret_string ()
{
    local retval=""

    if [ -f $1 ]; then
        echo >&2 "file $1 exists"
        retval="true"
    else
        echo >&2 "file $1 not exists"
        retval="false"
    fi
    echo "$retval"
}


# call_exit_status
# retval=$?
# if [ "$retval" == 0 ]; then
#      echo "result is int 0"
# else
#      echo "result is not int 0"
# fi
call_exit_status ()
{
    local retval=1

    if [ -f $1 ]; then
        echo >&2 "file $1 exists"
        retval=0
    else
        echo >&2 "file $1 not exists"
        retval=1
    fi
    return "$retval"
}


# call_exit_status
# retval=$?
# if [ "$retval" == 0 ]; then
#      echo "result is int 0"
# else
#      echo "result is not int 0"
# fi
retval=-1
call_share_var()
{
    if [ -f $1 ]; then
        echo >&2 "file $1 exists"
        retval=0
    else
        echo >&2 "file $1 not exists"
        retval=1
    fi
}

LogicAndOr ()
{
    printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"

    #cat /etc/shadow 2>/dev/null || Echo "Failed to open file"
    #cat /etc/shadow 2>/dev/null || Die "Failed to open file"

    printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
}

