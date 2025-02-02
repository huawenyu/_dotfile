# library.awk
# Cut part from https://github.com/dubiousjim/awkenough/blob/master/library.awk
# globals EXITCODE, MISSING
#
## regexp utils #########
## WARNING: /re/ evaluates as boolean, so have to pass "re"s to user functions
@namespace "regex"

# populate array from str="key key=value key=value"
# can optionally supply "re" for equals, space; if they're the same or equals is "", array will be setlike
function asplit(str, array,  equals, space,   aux, i, n) {
    n = split(str, aux, (space == "") ? "[ \n]+" : space)
    if (space && equals == space)
        equals = ""
    else if (ismissing(equals))
        equals = "="
    split("", array) # delete array
    for (i=1; i<=n; i++) {
        if (equals && match(aux[i], equals))
            array[substr(aux[i], 1, RSTART-1)] = substr(aux[i], RSTART+RLENGTH)
        else
            array[aux[i]]
    }
    split("", aux) # does it help to delete the aux array?
    return n
}


# like lua's find("%b()"), --> RSTART and sets RSTART and RLENGTH
function bmatch (s, opener, closer,   len, i, n, c) {
    len = length(s)
    n = 0
    for (i=1; i <= len; ++i) {
        c = substr(s, i, 1)
        if (c == opener) {
            if (n == 0) RSTART = i
            ++n
        } else if (c == closer) {
            --n
            if (n == 0) {
                RLENGTH = i - RSTART + 1
                return RSTART
            }
        }
    }
    return 0
}


# TODO
# tail not defined for negative nth (doesn't make sense, will always be none)
# negative nth with zero-length matches:
#   - head returns one element too early, or sometimes wrongly?
#   - matchstr diverges
function tail(str,  re, nth, m,  start, n) {
    nth = checkpos(nth, 1, "tail: third argument must be positive")
    re = check(re, SUBSEP)
    if (nth == 1) {
        if (match(str, re)) {
            m = substr(str, RSTART + RLENGTH)
            RSTART += RLENGTH
            RLENGTH = length(m)
        }
        return m
    } else {
        RLENGTH = -1
        start = 1
        while (nth--) {
            if (RLENGTH > 0) {
                str = substr(str, RSTART + RLENGTH)
                start += RLENGTH - 1
            } else if (RLENGTH == 0) {
                start++
                if ((str = substr(str, RSTART + 1)) == "") {
                    nth--
                    break
                }
            }
            n = (RLENGTH > 0)
            if (!match(str, re)) break
            if (n && !RLENGTH) {
                assert(RSTART == 1 && nth >= 0)
                if ((str = substr(str, 2)) == "" || !match(str, re)) break
                start++
            }
            start += RSTART + n - 1
        }
        if (nth >= 0) {
            RSTART = 0
            RLENGTH = -1
        } else {
            m = substr(str, RSTART + RLENGTH)
            RSTART = start + RLENGTH
            RLENGTH = length(m)
        }
        return m
    }
}


# this returns items between "re"; matchstr returns what matches "re"
# 3rd argument to specify which item (-1 for last)
# defaults to re=SUBSEP nth=1st none=""
function head(str, re, nth,  none,   start, m, n) {
    if (nth != -1) {
        nth = checkpos(nth, 1, "head: third argument must be positive")
    }
    re = check(re, SUBSEP)
    if (nth == 1) {
        if (match(str, re)) {
            RLENGTH = RSTART - 1
            str = substr(str, 1, RLENGTH)
        } else {
            RLENGTH = length(str)
        }
        RSTART = 1
        return str
    } else {
        # # to get arbitrary item, we just split
        # nf = split(str, aux, re)
        # if (nth == -1 && nf > 0)
        #     m = aux[nf]
        # else if (nth in aux)
        #     m = aux[nth]
        # split("", aux) # does it help to delete the aux array?
        # return m

        # I simplified and streamlined as much as I could, while still passing tests.
        m = (nth > 0) ? none : ""
        RLENGTH = -1
        start = 1
        while (nth--) {
            if (RLENGTH > 0) {
                str = substr(str, RSTART + RLENGTH)
                start += RSTART + RLENGTH - n
                m = (nth > 0) ? none : str
            } else if (RLENGTH==0) {
                start += RSTART + 1
                m = n ? substr(str, 2, 1) : str
                if ((str = substr(str, 2+n)) == "") {
                    if (!m || nth > 1) {
                        RSTART = 0
                        RLENGTH = -1
                        return none
                    } else if (nth-- > 0)
                        m = ""
                    else
                        start--
                    break
                }
            }
            n = (RLENGTH > 0)
            if (!match(str, re)) break
            if (RSTART > 1)
                m = substr(str, 1, RSTART-1)
            else
                m = (n && RLENGTH) ? "" : substr(m, 1, 1)
            start += n - 1
        }
        if (nth <= 0) {
            RSTART = start
            RLENGTH = length(m)
        }
        return m
    }
}


# 3rd argument to specify occurrence (default=1st, -1=last)
# permits one 0-length match at RSTART = length(str)+1
function matchstr(str, re, nth,  none,   m, start, len, n) {
    start = n = 0
    if (nth == -1) {
        # find last occurrence
        len = -1
        m = none
        while (match(str, re)) {
            start = (n += RSTART)
            len = RLENGTH
            m = substr(str, RSTART, RLENGTH)
            # handle 0-length match
            if (!RLENGTH) RLENGTH++
            n += RLENGTH - 1
            str = substr(str, RSTART + RLENGTH)
        }
        RSTART = start
        RLENGTH = len
        return m
    }
    nth = checkpos(nth, 1, "matchstr: third argument must be positive")
    RLENGTH = -1
    start = 1
    while (nth--) {
        if (RLENGTH > 0) {
            str = substr(str, RSTART + RLENGTH)
            start += RLENGTH - 1
        } else if (RLENGTH == 0) {
            start++
            if ((str = substr(str, RSTART + 1)) == "") {
                nth--
                break
            }
        }
        n = (RLENGTH > 0)
        if (!match(str, re)) break
        if (n && !RLENGTH) {
            assert(RSTART == 1 && nth >= 0)
            if ((str = substr(str, 2)) == "" || !match(str, re)) break
            start++
        }
        start += RSTART + n - 1
    }
    if (nth >= 0) {
        RSTART = 0
        RLENGTH = -1
        return none
    } else {
        m = substr(str, RSTART, RLENGTH)
        RSTART = start
        return m
    }
}


# 3rd argument to specify occurrence (default=1st, -1=last)
function nthindex(str, needle, nth,   i, n, len, start) {
    start = 0
    n = 0
    len = length(needle)
    if (nth == -1) {
        # find last occurrence
        while ((i = index(str, needle)) > 0) {
            n = start + i
            start += (i + len -1)
            str = substr(str, i + len)
        }
        return n
    }
    nth = checkpos(nth, 1, "nthindex: third argument must be positive")
    do {
        if (n > 0) {
            str = substr(str, n + len)
            start += (len -1)
        }
        n = index(str, needle)
        start += n
    } while (n && --nth)
    return nth ? 0 : start
}


# gawk's match does only a single match, and returns \0,\1..\n, starts, and lengths in a single array
# this function does global match, and returns only \0 and starts, in two arrays
function gmatch(str, re,  ms, starts,   i, n, start, sep1, sep2) {
    # find separators that don't occur in str
    i = 1
    do
        sep1 = sprintf("%c", i++)
    while (sep1 ~ /[][^$(){}.*+?|\\]/ || index(str, sep1))
    do
        sep2 = sprintf("%c", i++)
    while (index(str, sep2))
    split("", starts) # delete array
    n = gsub(re, sep1 "&" sep2, str)
    split(str, ms, sep1)
    start = 1
    for (i=1; i<=n; i++) {
        start += length(ms[i])
        starts[i] = start--
        ms[i] = substr(ms[i+1], 1, index(ms[i+1], sep2) - 1)
    }
    delete ms[i]
    return n
}


# function gmatch(str, re,  ms, starts,   n, i, start, stop, eaten, sep1, sep2) {
#     n = 0
#     eaten = 0
#     # find separators that don't occur in str
#     i = 1
#     do
#         sep1 = sprintf("%c", i++)
#     while (index(str, sep1))
#     do
#         sep2 = sprintf("%c", i++)
#     while (index(str, sep2))
#     split("", ms) # delete array
#     split("", starts) # delete array
#     i = gsub(re, sep1 "&" sep2, str)
#     while (i--) {
#         start = index(str, sep1)
#         stop = index(str, sep2) - 1
#         # testing for the arrays interpret them as scalar; just use them
#         ms[++n] = substr(str, start + 1, stop - start)
#         starts[n] = eaten + start
#         eaten += stop - 1
#         str = substr(str, stop + 2)
#     }
#     return n
# }


# based on <http://awk.freeshell.org/FindAllMatches>
# function gmatch(str, re,  ms, starts,   n, i, eaten) {
#     n = 0
#     eaten = 0
#     # we check number of matches to help avoid rematching anchored REs
#     # but note this isn't a reliable solution: "^a|b" will wrongly match indices 1 and 2 of "aab"
#     i = gsub(re, "&", str)
#     while (i-- && match(str, re) > 0) {
#         # testing for the arrays interpret them as scalar; just use them
#         ms[++n] = substr(str, RSTART, RLENGTH)
#         starts[n] = eaten + RSTART
#         # handle 0-length match
#         if (!RLENGTH) RLENGTH++
#         eaten += (RSTART + RLENGTH -1)
#         str = substr(str, RSTART + RLENGTH)
#     }
#     return n
# }


# behaves like gawk's split; special cases re == "" and " "
# unlike split, will honor 0-length matches
function gsplit(str, items, re,  seps,   n, i, start, stop, sep1, sep2, sepn) {
    n = 0
    # find separators that don't occur in str
    i = 1
    do
        sep1 = sprintf("%c", i++)
    while (index(str, sep1))
    do
        sep2 = sprintf("%c", i++)
    while (index(str, sep2))
    sepn = 1
    split("", seps) # delete array
    if (ismissing(re))
        re = FS
    if (re == "") {
        split(str, items, "")
        n = length(str)
        for (i=1; i<n; i++)
            seps[i]
        return n
    }
    split("", items) # delete array
    if (re == " ") {
        re = "[ \t\n]+"
        if (match(str, /^[ \t\n]+/)) {
            seps[0] = substr(str, 1, RLENGTH)
            str = substr(str, RLENGTH+1)
        }
        if (match(str, /[ \t\n]+$/)) {
            sepn = substr(str, RSTART, RLENGTH)
            str = substr(str, 1, RSTART-1)
        }
    }
    i = gsub(re, sep1 "&" sep2, str)
    while (i--) {
        start = index(str, sep1)
        stop = index(str, sep2) - 1
        seps[++n] = substr(str, start + 1, stop - start)
        items[n] = substr(str, 1, start - 1)
        str = substr(str, stop + 2)
    }
    items[++n] = str
    if (sepn != 1) seps[n] = sepn
    return n
}


