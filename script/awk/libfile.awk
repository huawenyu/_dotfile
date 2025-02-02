@namespace "file"
@include "libstd.awk"

# Usage:
#   {print FILENAME, filename(FILENAME)}
function filename(file, a, n) {
	n = split(file, a, "/")
	return a[n]
}


# Usage:
#   {print FILENAME, filedir(FILENAME)}
function filedir(file, a, n) {
	n = split(file, a, "/")
	return std::join(a, 1, n - 1, "/")
}

## os/filesystem #########

# assert(system(cmd) == 0, "system(\"" cmd "\") failed")


function isreadable(path) {
    return (system("test -r " quote(path)) == 0)
}

# function isreadable(path,   v, res) {
#     res = 0
#     if ((getline v < path) >= 0) {
#         res = 1 # though file may be empty
#         close(path)
#     }
#     return res
# }


function filesize(path,   followlink,  v, cmd) {
    cmd = "ls -ld " (followlink ? "-L " : "") quote(path) " 2>/dev/null"
    if (0 < (cmd | getline v)) {
        close(cmd)
        if (v ~ /^-/) {
            return head(v, " ", 5) # filesize
        } else {
            return "" # not regular file
        }
    } else {
        close(cmd)
        return -1 # file doesn't exist
    }
}


function filetype(path,   followlink,  v, cmd) {
    cmd = "ls -ld " (followlink ? "-L " : "") quote(path) " 2>/dev/null"
    if (0 < (cmd | getline v)) {
        close(cmd)
        v = substr(v, 1, 1) # -dlcbsp
        if (v == "-")
            return "f" # this ensures that error result < all non-error results
        else
            return v
    } else {
        close(cmd)
        return -1 # file doesn't exist
    }
}


function basename(path, suffix) {
    sub(/\/$/, "", path)
    if (path == "")
        return "/"
    sub(/^.*\//, "", path)
    if (suffix != "" && has_suffix(path, suffix))
        path = substr(path, 1, length(path) - length(suffix))
    return path
}


function dirname(path) {
    if (!sub(/\/[^\/]*\/?$/, "", path))
        return "."
    else if (path != "")
        return path
    else
        return "/"
}


function getfile(path,   v, p, res) {
    res = p = ""
    while (0 < (getline v < path)) {
        res = res p v
        p = "\n"
    }
    assert(close(path) == 0, "close(\"" path "\") failed")
    return res
}


function getpipe(cmd,   v, p, res) {
    res = p = ""
    while (0 < (cmd | getline v)) {
        res = res p v
        p = "\n"
    }
    assert(close(cmd) == 0, "close(\"" cmd "\") failed")
    return res
}


# creates a file that will be deleted when awk exits; works on FreeBSD, should also work on BusyBox, whose `trap` accepts only numeric signals; also FreeBSD permits `mktemp -t awk` but BusyBox requires `mktemp -t /tmp/awk.XXXXXX`
function mktemp(   cmd, v) {
    # base directory is -p DIR, else ${TMPDIR-/tmp}
    # -t tmp.XXXXXX or TEMPLATE
    cmd = "T=`mktemp \"${TMPDIR:-/tmp}/awk.XXXXXX\"` || exit 1; trap \"rm -f '$T'\" 0 1 2 3 15; printf '%s\n' \"$T\"; cat /dev/zero"
#     0/EXIT
#     1/HUP: controlling terminal or process died
#     2/INT ^C from keyboard
#     15/TERM

#     3/QUIT ^\ from keyboard
#     6/ABRT from abort(2)
#     13/PIPE: write to pipe with no readers
#     14/ALRM from alarm(2), e.g. if script calls sleep

# other stty keys: eof=^d start/stop=^q/^s susp=^z dsusp=^y
#                  erase/erase2=^?/^h werase=^w kill=^u reprint=^r lnext=^v
#                  flush/discard=^o status=^t

    if (0 < (cmd | getline v)) {
        return v
    } else {
        return ""
    }
    # we intentionally don't close the pipe
}

