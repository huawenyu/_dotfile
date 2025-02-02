# The array functions:
#
# https://www.gnu.org/software/gawk/manual/html_node/Walking-Arrays.html
#
@namespace "array"

# Usage:
# BEGIN {
#     a[1] = 1
#     a[2][1] = 21
#     a[2][2] = 22
#     a[3] = 3
#     a[4][1][1] = 411
#     a[4][2] = 42
#
#     walk(a, "a")
# }
function walk(arr, name, comma,      i, _func)
{
	for (i in arr) {
		if (awk::isarray(arr[i])) {
			if (comma)
				walk(arr[i], (name comma i), comma)
			else
				walk(arr[i], (name "[" i "]"), comma)
		} else if (i ~ "^_@_") { #indrect function
			_func = arr[i]
			if (_func)
				@_func()
		} else if (comma) {
			printf("%s%s%s = %s\n", name, comma, i, arr[i])
		} else {
			printf("%s[%s] = %s\n", name, i, arr[i])
		}
	}
}

# Usage:
# BEGIN {
#      family["me"]["father"]["grandpa"]["name"] = "George"
#      family["me"]["father"]["grandpa"]["age"]  = 70
#      family["me"]["father"]["grandma"]["name"] = "Katherine"
#      family["me"]["father"]["name"]            = "Vasiliy"
#      family["me"]["name"]                      = "Ivan"
#      array::show(family, "Family")
# }
function show(arr, arrname, skip,     elt, member, arrnum)
{
	if (!awk::isarray(arr)) {
		if (index(skip, elt) == 0) {
			print indent arrname member "[\033[1;31m" elt "\033[0m]=\"\033[1;32m" arr "\033[0m\""
		}
	} else {
		arrnum = elt
		member = elt ? member "[" elt "]" : ""
		#print indent (elt ? arrname member : arrname) "(\033[1;34m" length(arr) " member" (length(arr) > 1 ? "s" : "") "\033[0m)"
		indent = indent " "
		for (elt in arr) {
			if (elt ~ "^_@_") { #indrect function
				_func = arr[elt]
				if (_func)
					@_func()
			} else if (index(skip, elt) == 0) {
				show(arr[elt], arrname, skip, elt, member, arrnum)
			}
		}
		indent = substr(indent, 1, length(indent)-1)
	}
}

function show2(arr, arrname, skip)
{
	indent = ""
	show(arr, arrname, skip)
	indent = ""
}

# Usage:
# BEGIN {
#     a[1] = 1
#     a[2][1] = 21
#     a[2][2] = 22
#     a[3] = 3
#     a[4][1][1] = 411
#     a[4][2] = 42
#
#     walk2(a, "a", "do_print", 0)
# }
#
# function do_print(name, element)
# {
#     printf "%s = %s\n", name, element
# }
function walk2(arr, name, process, do_arrays,   i, new_name)
{
	for (i in arr) {
		new_name = (name "[" i "]")
		if (awk::isarray(arr[i])) {
			if (do_arrays)
				@process(new_name, arr[i])
			walk2(arr[i], new_name, process, do_arrays)
		} else
			@process(new_name, arr[i])
	}
}


function copy(dst, src,      i)
{
	delete dst         # Empty "dst" for first call and delete the temp
	# array added by dst[i][1] below for subsequent.
	for (i in src) {
		if (isarray(src[i])) {
			dst[i][1]  # Force dst[i] to also be an array by creating a temp
			copy(src[i], dst[i])
		}
		else {
			dst[i] = src[i]
		}
	}
}

# function clone(lhs, rhs)
# {
#     for (i in rhs) {
#         if (isarray(rhs[i])) {
#             lhs[i][1] = ""
#             delete lhs[i][1]
#             clone(lhs[i], rhs[i])
#         } else {
#             lhs[i] = rhs[i]
#         }
#     }
# }

#Usage: join an array into a string
function join(array, start, end, sep,    result, i)
{
	if (sep == "")
		sep = " "
	else if (sep == SUBSEP) # magic value
		sep = ""
	result = array[start]
	for (i = start + 1; i <= end; i++)
		result = result sep array[i]
	return result
}

# Shuffle an array with indexes from 1 to n. (Knuth or Fisher-Yates shuffle)
function shuffle(A, n,    i, j, t) {
    if (!n) {
        n = 1
        while (n in A) n++
        n--
    }
    for (i = n; i > 1; i--) {
            j = int(i * rand()) + 1 # random integer from 1 to i
            t = A[i]; A[i] = A[j]; A[j] = t # swap A[i], A[j]
    }
}


## array utils #########

function isempty(array,   i) {
    for (i in array) return 0
    return 1
}


# insertion sort A[1..n]
# stable, O(n^2) but fast for small arrays
function sort(A,n,   i,j,t) {
    if (!n) {
        n = 1
        while (n in A) n++
        n--
    }
    for (i = 2; i <= n; i++) {
        t = A[i]
        for (j = i; j > 1 && A[j-1] > t; j--)
            A[j] = A[j-1]
        A[j] = t
    }
}

# mergesort is stable, O(n log n) worst-case
# on arrays uses O(n) auxiliary space; but on linked lists only a small constant space
# implementation not provided here


# in-place quicksort A[left..right]
# for efficiency, left and right must be supplied, default values aren't calculated
# unstable
# on avg thought to be constantly better than heapsort, but has worst-case O(n^2)
# choose random pivot to avoid worst-case behavior on already-sorted arrays
# advantage over mergesort is that it only uses O(log n) auxiliary space (if we have tail-calls)
function qsort(A,left,right,   i,last,t) {
    if (left >= right)  # do nothing if array contains at most one element
        return
    i = left + int((right-left+1)*rand()) # choose pivot
    t = A[left]; A[left] = A[i]; A[i] = t # swap A[left] and A[i]
    last = left
    for (i = left+1; i <= right; i++)
        if (A[i] < A[left]) {
            ++last
            t = A[last]; A[last] = A[i]; A[i] = t # swap A[last] and A[i]
        }
    t = A[left]; A[left] = A[last]; A[last] = t # swap A[left] and A[last]
    qsort(A, left, last-1)
    qsort(A, last+1, right)
}


# heapsort
# also unstable, and unlike merge and quicksort it relies on random-access so has poorer cache performance
# advantage over quicksort is that its worst-case same as avg: O(n log n)
# this presentation based on http://dada.perl.it/shootout/heapsort.lua5.html
function hsort(A, n,   c, p, t, i) {
    if (!n) {
        n = 1
        while (n in A) n++
        n--
    }
    i = int(n/2) + 1
    while (1) {
        if (i > 1) {
            i--
            t = A[i]
        } else {
            t = A[n]
            A[n] = A[1]
            n--
            if (n == 1) {
                A[1] = t
                return
            }
        }
        for (p = i; (c = 2*p) <= n; p = c) {
            if ((c < n) && (A[c] < A[c+1]))
                c++
            if (t < A[c])
                A[p] = A[c]
            else break
        }
        A[p] = t
    }
}

# # one of the more usual presentations
# function hsort(A,n,  i,t) {
#     if (!n) {
#         n = 1
#         while (n in A) n++
#         n--
#     }
#     for (i = int(n/2); i >= 1; i--)
#         heapify(A, i, n)
#     for (i = n; i > 1; i--) {
#         t = A[1]; A[1] = A[i]; A[i] = t # swap A[1] and A[i]
#         heapify(A, 1, i-1)
#     }
# }
#
# function heapify(A,left,right,   p,c,t) {
#     for (p = left; (c = 2*p) <= right; p = c) {
#         if (c < right && A[c] < A[c+1])
#             c++
#         if (A[p] < A[c]) {
#             t = A[c]; A[c] = A[p]; A[p] = t # swap A[c] and A[p]
#         } else break
#     }
# }


# if used on $0, rewrites it using OFS
#   if you want to preserve existing FS, need to use gsplit
# can also be used on array
# returns popped elements separated by SUBSEP
function pop(start,  len, A,   stop, p, last) {
    start = checkpos(start, 0, "pop: first argument must be positive")
    len = checknat(len, 0, "pop: second argument must be >= 0")
    if (isempty(A)) {
        if (!start)
            start = NF
        if (!len && !MISSING)
            return "" # explicit len=0
        if (!len)
            len = NF - start + 1
        stop = start + len - 1
        p = res = ""
        for(; ++stop <= NF; ++start) {
            if (len-- > 0) {
                res = res p $start
                p = SUBSEP
            }
            $start = $stop
        }
        stop = start - 1
        for (; start <= NF; ++start) {
            if (len-- > 0) {
                res = res p $start
                p = SUBSEP
            }
        }
        NF = stop
        if (!p) {
            # nawk won't recompute $0 just because NF was mutated
            if (NF) $1 = $1
            else $0 = ""
        }
        return res
    } else {
        # using array
        last = 1
        while (last in A) last++
        last--
        if (!start)
            start = last
        if (!len && !MISSING)
            return "" # explicit len=0
        if (!len)
            len = last - start + 1
        stop = start + len - 1
        p = res = ""
        for(; ++stop <= last; ++start) {
            if (len-- > 0) {
                res = res p A[start]
                p = SUBSEP
            }
            A[start] = A[stop]
        }
        for (; start <= last; ++start) {
            if (len-- > 0) {
                res = res p A[start]
                p = SUBSEP
            }
            delete A[start]
        }
        return res
    }
}


function insert(value, start,  A,   stop, last) {
    start = checkpos(start, 0, "insert: second argument must be positive")
    if (isempty(A)) {
        if (!start)
            start = NF + 1
        for (stop = NF; stop >= start; stop--) {
            $(stop+1) = $stop
        }
        $start = value
        return NF
    } else {
        # using array
        last = 1
        while (last in A) last++
        last--
        if (!start)
            start = last+1
        for (stop = last; stop >= start; stop--) {
            A[stop+1] = A[stop]
        }
        A[start] = value
        return (start > last) ? start : last + 1
    }
}


function extend(V, start,  A,   stop, lastV, last) {
    start = checkpos(start, 0, "insert: second argument must be positive")
    lastV = 1
    while (lastV in V) lastV++
    lastV--
    if (isempty(A)) {
        if (!lastV)
            return NF
        if (!start)
            start = NF + 1
        for (stop = NF; stop >= start; stop--) {
            $(stop+lastV) = $stop
        }
        for (start--; lastV > 0; lastV--)
            $(start+lastV) = V[lastV]
        return NF
    } else {
        # using array
        last = 1
        while (last in A) last++
        last--
        if (!lastV)
            return last
        if (!start)
            start = last+1
        for (stop = last; stop >= start; stop--) {
            A[stop+lastV] = A[stop]
        }
        last = (start > last) ? start + lastV - 1 : last + lastV
        for (start--; lastV > 0; lastV--)
            A[start + lastV] = V[lastV]
        return last
    }
}


function reverse(A,   i, t, last) {
    if (isempty(A)) {
        last = NF + 1
        for (i=1; i < last--; i++) {
            t = $i
            $i = $last
            $last = t
        }
    } else {
        # using array
        last = 1
        while (last in A) last++
        for (i=1; i < last--; i++) {
            t = A[i]
            A[i] = A[last]
            A[last] = t
        }
    }
}


# defaults to fields $start..$NF, using OFS
# if you want to preserve existing FS, need to use gsplit
# to concat an array without specifying len: concat(start, <uninitialized>, OFS, array)
function concat(start,  len, fs, A,   i, s, p, stop) {
    fs = check(fs, OFS)
    start = checkpos(start, 1, "concat: first argument must be positive")
    len = checknat(len, 0, "concat: second argument must be >= 0")
    if (!len && !MISSING)
        return "" # explicit len=0
    s = p = ""
    if (isempty(A)) {
        if (len)
            stop = start + len - 1
        else
            stop = NF
        # more with fields
        for (i=start; i<=stop; i++) {
            s = s p $i
            p = fs
        }
    } else {
        # using array
        if (len)
            stop = start + len - 1
        for (i=start; len ? i<=stop : i in A; i++) {
            s = s p A[i]
            p = fs
        }
    }
    return s
}


function has_value(A, value,   k) {
    for (k in A)
        if (k[A] == value)
            return true
    return false
}


# if onlykeys, values are ignored
function includes(A, B,  onlykeys,   k) {
    for (k in B)
        if (!(k in A && (onlykeys || A[k] == B[k])))
            return 0
    return 1
}


# if conflicts=0, drop keys; else favor A1 or A2; default=1
function union(A1, A2,  conflicts,   k) {
    conflicts = checknat(conflicts, 1, "union: third argument must be 0, 1, or 2")
    if (conflicts > 2) die("union: third argument must be 0, 1, or 2")
    for (k in A2)
        if (k in A1) {
           if (conflicts == 2)
                A1[k] = A2[k]
            else if (conflicts == 0 && A1[k] != A2[k])
                delete A1[k]
        } else {
            A1[k] = A2[k]
        }
}


# if conflicts=0, drop keys; else favor A1 or A2; default=1
function intersect(A1, A2,  conflicts,   k) {
    conflicts = checknat(conflicts, 1, "intersect: third argument must be 0, 1, or 2")
    if (conflicts > 2) die("intersect: third argument must be 0, 1, or 2")
    for (k in A1)
        if (k in A2) {
            if (conflicts == 2)
                A1[k] = A2[k]
            else if (conflicts == 0 && A1[k] != A2[k])
                delete A1[k]
        } else {
            delete A1[k]
        }
}


# if conflicts=0, drop keys; else keep them (favoring A1); default=1
function subtract(A1, A2,  conflicts,   k) {
    conflicts = checknat(conflicts, 1, "subtract: third argument must be 0 or 1")
    if (conflicts > 1) die("subtract: third argument must be 0 or 1")
    for (k in A2)
        if (k in A1) {
            if (conflicts == 0 || A1[k] == A2[k])
                delete A1[k]
        }
}


