# library.awk
# https://github.com/dubiousjim/awkenough/blob/master/library.awk
# globals EXITCODE, MISSING
#
@namespace "util"

# if you call die, assert, or check*: start END blocks with
#    { if (EXITCODE) exit EXITCODE; ... }
function die(msg) {
    EXITCODE=1
    printf("%s: %s\n", ARGV[0], msg) > "/dev/stderr"
    exit EXITCODE
}


function assert(test, msg) {
    if (!test) die(msg ? msg : "assertion failed")
}


# missing values are only isnull(), isnum(), iszero(), isint(), isnat() when a true second arg is supplied
# "" values (even if set from command-line) are only isnull()
# 0 and "0" values are isnum(), iszero(), isint(), isnat(), but other values coercable to 0 aren't
# floats are isnum() but not ispos(), isneg()


# unitialized scalar
function ismissing(u) {
    return u == 0 && u == ""
}


function check(u, missing) {
    if (u == 0 && u == "") {
        MISSING = 1
        return missing
    }
    MISSING = 0
    return u
}

# explicit ""
function isnull(s, u) {
    if (u) return s == "" # accept missing as well
    return !s && s != 0
}


function isnum(n, u) {
    # return n ~ /^[+-]?[0-9]+$/
    if (u) return n == n +0 # accept missing as well
    return n "" == n +0
    # NOTE: awk will also convert when there's leading space/trailing anything
    #       and will convert any other non-numeric to 0
}


# returns num or missing, else die(msg)
function checknum(n, missing, msg) {
    if (n "" == n + 0) {
        MISSING = 0
        return n # explicit numbers are preserved
    } else if (msg && n != n + 0) die(msg)
    MISSING = 1
    return missing
}


# explicit 0 or "0"
function iszero(n, u) {
    # return n + 0 == 0 # accept any coercable
    if (u) return n == 0 # accept missing as well
    return n == 0 && n != ""
}


function isint(n, u) {
    if (u) return int(n) == n # accept missing as well
    return int(n) == n && n != ""
}


# explicit isnum >= 0
function isnat(n, u) {
    if (u) return int(n) == n && n >= 0 # accept missing as well
    return int(n) == n && n "" >= 0
}


# returns nat or missing, else die(msg)
function checknat(n, missing, msg) {
    if (int(n) == n) {
        if (n "" >= 0) {
            MISSING = 0
            return n # explicit numbers are preserved
        } else if (msg && n < 0) die(msg)
    } else if (msg) die(msg)
    MISSING = 1
    return missing
}


# explicit isnum > 0
function ispos(n) {
    # return n "" == n +0 && n > 0 # accept float as well
    return int(n) == n && n > 0
}


# returns pos or missing, else die(msg)
function checkpos(n, missing, msg) {
    if (int(n) == n) {
        if (n "" > 0) {
            MISSING = 0
            return n # explicit numbers are preserved
        } else if (msg && (n < 0 || n "" >=  0)) die(msg)
    } else if (msg) die(msg)
    MISSING = 1
    return missing
}


function isneg(n) {
    # return n "" == n +0 && n < 0 # accept float as well
    return int(n) == n && n < 0
}



## numeric utils #########

# might as well inline
function max(m, n) { return (m > n) ? m : n }


# might as well inline
function min(m, n) { return (m < n) ? m : n }


# return k=1 distinct random elements A[1 <= i <= n], separated by SUBSEP
function choose(n,  k,   A, i, r, p) {
    k = checkpos(k, 1, "choose: second argument must be positive")
    if (!isempty(A)) {
        # A is already populated, choose k elements from A[1]..A[n], ordered by index
        if (!n) {
            n = 1
            while (n in A) n++
            n--
        }
        p = r = ""
        for (i = 1; n > 0; i++)
            if (rand() < k/n--) {
                p = p r A[i]
                r = SUBSEP
                k--
            }
        return p
    }
    # else choose k integers from 1..n, ordered
    if (k == 1)
        return int(n*rand())+1
    for (i = n-k+1; i <= n; i++)
        ((r = int(i*rand())+1) in A) ? A[i] : A[r]
    p = r = ""
    for (i=1; i<=n; i++)
       if (i in A) {
            p = p r i
            r = SUBSEP
        }
    split("", A) # does it help to delete the aux array?
    return p
}


# random permutation of k=n integers between 1 and n
# a random deck is: split(permute(52,52), deck, SUBSEP)
function permute(n,  k,   i, r, p) {
    k = checkpos(k, n, "permute: second argument must be positive")
    p = SUBSEP
    for (i = n-k+1; i <= n; i++) {
        if (p ~ SUBSEP (r = int(i*rand())+1) SUBSEP)
            # since i is higher than before, p only contains r when r < i
            sub(SUBSEP r SUBSEP, SUBSEP r SUBSEP i SUBSEP, p)    # put i after r
        else p = SUBSEP r p                                      # put r at beginning
    }
    return substr(p, 2, length(p)-2)
}



## debugging #########

function dump(array,  prefix,   i,j) {
    for (i in array) {
        j = i
        gsub(/\\/, "\\134", j)
        gsub(/,/, "\\054", j)
        gsub(/\t/, "\\t", j)
        gsub(/\n/, "\\n", j)
        gsub(/\r/, "\\r", j)
        gsub(/\b/, "\\b", j)
        gsub(/\f/, "\\f", j)
#         gsub(/\a/, "\\a", j)
#         gsub(/\v/, "\\v", j)
        gsub(SUBSEP, ",", j)
        gsub(/[\001-\037]/, "¿", j) # TODO: convert to octal?
        printf "%s[%s]=<%s>\n", prefix, j, array[i]
    }
}


# idump(array, [[start],stop], [prefix])
function idump(array,  stop, prefix,   i, start) {
    if (isnum(prefix)) {
        start = stop
        stop = prefix
        prefix = i
    } else start = 1
    for (i=start; !stop || i<=stop; i++)
        if (i in array) {
            printf "%s[%d]=<%s>\n", prefix, i, array[i]
        } else if (!stop) break
}


## getopt-handling #########

function usage(basename, version, description, summary, longsummary, addl, optstring, options, minargs) {
    gsub(/\n/, "\n ", longsummary)
    description = "Usage:   " basename " " summary "\n         " description "\nAuthor:  Jim Pryor <dubiousjim@gmail.com>\nVersion: " version "\n\nOptions:\n " longsummary (addl ? "\n\n" addl : "") "\n\nThis script is in the public domain, free from copyrights or restrictions."
    getopt(optstring, options, basename, version, description)
    if (ARGC - 1 < minargs) {
        print description > "/dev/stderr"
        exit 2
    }
}


function getopt(optstring, options, basename, version, usage_msg,   i, j, o, m, n, a, d) {
    # options["long"] = ""         option with no argument
    # options["long"] = ":"        option with required argument, only remember last occurrence
    # options["long"] = "?default" option with optional argument, only remember last occurrence
    # options["long"] = "+"        repeatable option with required argument, results will be separated by SUBSEP
    # options["long"] = "*default" repeatable option with optional argument, results will be separated by SUBSEP (not useful? disabled)

    # optstring = "ab:c?d+e*" ~~> { a="", b=":", c="?", d="+", e="*" }

    for (i=1; i<=length(optstring); ) {
        options[m = substr(optstring, i++, 1)]
        if (substr(optstring, i, 1) ~ /[:+?]/)  # /[:+?*]/ disabled *
            options[m] = substr(optstring, i++, 1)
    }

    for (i=1; i<ARGC; ) {
        if (ARGV[i] == "--") {
            # end of option arguments
            i++
            break
        } else if (ARGV[i] ~ /^--[a-z][a-z]/) {
            m = substr(ARGV[i++], 3)
            if (m == "version") {
                printf "%s version %s\n", basename, version > "/dev/stderr"
                exit 0
            } else if (m == "help") {
                print usage_msg > "/dev/stderr"
                exit 0
            }
            if (j = index(m, "=")) {
                a = substr(m, j+1)
                m = substr(m, 1, j-1)
            }
            if (!(m in options)) {
                printf "%s: unknown option --%s\n", basename, m > "/dev/stderr"
                exit 2
            }
        } else if (ARGV[i] ~ /^--/) {
            printf "%s: unknown option %s\n", basename, ARGV[i] > "/dev/stderr"
            exit 2
        } else if (ARGV[i] ~ /^-./) { 
            m = substr(ARGV[i], 2, 1)
            if (length(ARGV[i]) == 2) {
                j = 0 # no argument yet
                i++
            } else {
                j = 1 # flag unknown argument
                a = substr(ARGV[i], 3)
                ARGV[i] = "-" a
            }
            if (!(m in options)) {
                printf "%s: unknown option -%s\n", basename, m > "/dev/stderr"
                exit 2
            }
        } else {
            # first non-option argument
            break
        }

        n = substr(options[m], 1, 1)
        if (n == ":" || n == "+") {
            if (j==1) {
                # consume rest of current ARGV
                i++
            } else if (j==0)
                if (i<ARGC && (a = ARGV[i]) !~ /^-/)
                    i++
                else {
                    printf "%s: option -%s%s missing required argument\n", basename, (length(m)==1) ? "" : "-", m > "/dev/stderr"
                    exit 2
                }
            # :[SUBSEP arg] gets reassigned
            # +[SUBSEP arg...] is repeatable
            options[m] = ((n==":") ? n : options[m]) SUBSEP a
        } else if (n == "?") {  #   || n == "*" disabled *
            d = index(options[m], SUBSEP)
            d = substr(options[m], 2, d ? d-1 : length(options[m]))
            if (j==1) {
                # consume rest of current ARGV
                i++
            } else if (j==0)
                if (i<ARGC && (a = ARGV[i]) !~ /^-/)
                    i++
                else {
                    # missing optional argument
                    a = d
                }
            # ?default[SUBSEP arg] gets reassigned
            # *default[SUBSEP arg...] is repeatable
            options[m] = ((n=="?") ? "?" d : options[m]) SUBSEP a
        } else {
            if (j>1) {
                printf "%s: option --%s doesn't accept an argument\n", basename, m > "/dev/stderr"
                exit 2
            }
            options[m] = ++o
        }
    }
    if (i>1) {
        for (j=1; i<ARGC; )
            ARGV[j++] = ARGV[i++]
        ARGC = j
    }
    for (m in options) {
        if (options[m] ~ /^[:+?*]/) {
            if (j = index(options[m], SUBSEP))
                options[m] = substr(options[m], j+1)
            else
                delete options[m]
        } else if (!(options[m]))
            delete options[m]
    }
}

