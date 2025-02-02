# library.awk
# Cut part from https://github.com/dubiousjim/awkenough/blob/master/library.awk
# globals EXITCODE, MISSING
#
@namespace "string"

# Usage:  turn a byte into readable 1's and 0's
function bits2str(bits,        data, mask)
{
	if (bits == 0)
		return "0"

	mask = 1
	for (; bits != 0; bits = rshift(bits, 1))
		data = (and(bits, mask) ? "1" : "0") data

	while ((length(data) % 8) != 0)
		data = "0" data

	return data
}


## string utils #########


# 'quote' str for shell
function quote(str) {
    gsub(/'/, "'\\''", str)
    return "'" str "'"
}


# delete "quoted" spans, honoring \\ and \"
function delete_quoted(str, repl) {
#     gsub(/"((\\")*([^"\\]|\\[^"])*)*"/, repl, str)
    gsub(/"([^"\\]|\\.)*"/, repl, str)
    return str
}



# repeat str n times, from http://awk.freeshell.org/RepeatAString
function rep(str, n,  sep,   remain, result) {
    if (n < 2) {
        remain = (n == 1)
        result = sep = ""
    } else {
        remain = (n % 2 == 1)
        result = rep(str, (n - remain) / 2, sep)
        result = result sep result
    }
    return result (remain ? sep str  :"")
}


# -- remove trailing and leading whitespace from string
function trim(str) {
    if (match(str, /[^ \t\n].*[^ \t\n]/))
        return substr(str, RSTART, RLENGTH)
    else if (match(str, /[^ \t\n]/))
        return substr(str, RSTART, 1)
    else
        return ""
}

# # faster than either of:
# function trim2(str) {
#     sub(/^[ \t\n]+/, "", str)
#     sub(/[ \t\n]+$/, "", str)
#     return str
# }
# function trim3(str,  from) {
#     match(str, /^[ \t\n]*/)
#     if ((from = RLENGTH) < length(str)) {
#         match(str, /.*[^ \t\n]/)
#         return substr(str, from+1, RLENGTH-from)
#     } else return ""
# }


# -- remove leading whitespace from string
function trimleft(str) {
    if (match(str, /^[ \t\n]+/))
        return substr(str, RLENGTH+1)
    else
        return str
}

# # nearly the same performance as
# function trimleft2(str) {
#     sub(/^[ \t\n]+/, "", str)
#     return str
# }


# -- remove trailing whitespace from string
function trimright(str) {
    if (match(str, /.*[^ \t\n]/))
        return substr(str, RSTART, RLENGTH)
    else
        return ""
}

function trimprint(str)
{
    gsub(/[\001-\007\013\016-\037\n\r]/, "", str)
    return str
}

# # faster than either of:
# function trimright2(str,   n) {
#     n = length(str)
#     while (n && match(substr(str, n), /^[ \t\n]/)) n--
#     return substr(str, 1, n)
# }
# function trimright3(str) {
#     sub(/[ \t\n]+$/, "", str)
#     return str
# }


# TODO
## cut to max of 10 chars: `sprintf "%.10s", str`


# TODO
# function string:linewrap(width, indent)
#     checktype(self, 1, "string")
#     checkopt(width, 2, "positive!") or 72
#     checkopt(indent, 3, "natural!") or 0
#     local pos = 1
#     -- rest needs to be converted from Lua
#     return self:gsub("(%s+)()(%S+)()",
#         function(sp, st, word, fi)
#             if fi - pos > width then
#                 pos = st
#                 return "\n" .. rep(" ", indent) .. word
#             end
#         end)
# end


function beginwith(str, pre,   len1)
{
	len1 = length(pre)
	return substr(str, 1, len1) == pre
}


function endwith(str, suf,   len0, len2)
{
	len0 = length(str)
	len2 = length(suf)
	return len2 <= len0 && substr(str, len0 - len2 + 1) == suf
}


function trimprefix(str, pre,   len0, len1)
{
	len0 = length(str)
	len1 = length(pre)
	if (substr(str, 1, len1) == pre) {
		return substr(str, len1+1)
	} else {
		return str
	}
}

function trimsuffix(str, pre,   len0, len2)
{
	len0 = length(str)
	len2 = length(suf)
	if (len2 <= len0 && substr(str, len0 - len2 + 1) == suf) {
		return substr(str, 1, len0 - len2)
	} else {
		return str
	}
}

function contain(str, word,   len2) {
    return index(str, word) != 0
}


function detab(str, siz,    n, r, s, start) {
    siz = checkpos(siz, 8, "detab: second argument must be positive")
    r = ""
    n = start = 0
    while (match(str, "\t")) {
        start += RSTART
        s = siz - (start - 1 + n) % siz
        n += s - 1
        r = r substr(str, 1, RSTART-1) rep(" ", s)
        str = substr(str, RSTART+1)
    }
    return r str
}


function entab(str, siz) {
    siz = checkpos(siz, 8, "detab: second argument must be positive")
    str = detab(str, siz)
    gsub(".{" siz "}", "&\1", str)
    gsub("  +\1", "\t", str)
    gsub("\1", "", str)
    return str
}


