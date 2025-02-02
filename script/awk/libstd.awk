# The general library from gawk standlib
#
# https://github.com/gvlx/gawk/tree/master/awklib/eg/lib
#
@namespace "std"

# Used by getopt
BEGIN {
	Opterr = 1    # default is to diagnose
	Optind = 1    # skip ARGV[0]

	# test program
	if (awk::_getopt_test) {
		printf("----- awk::getopt -------\n")
		printf("  Option:\n")
		while ((_go_c = getopt(ARGC, ARGV, "ab:cd")) != -1) {
			printf("\tc = '%c', optarg = '%s'\n", _go_c, Optarg)
		}
		printf("  non-option:\n")
		for (; Optind < ARGC; Optind++) {
			printf("\tARGV[%d] = '%s'\n", Optind, ARGV[Optind])
		}
		printf("----- endof awk::getopt -------\n")
	}
}


# Usage: assert that a condition is true. Otherwise exit.
function assert(condition, string)
{
	if (! condition) {
		printf("%s:%d: assertion failed: %s\n",
										 FILENAME, FNR, string) > "/dev/stderr"
		_assert_exit = 1
		exit 1
	}
}


# Usage: join the fields range [start,end]
function join_fields(start,end,str_split,   i_, ret_)
{
	for (i_ = start; i_ <= end; i_++) {
		ret_ = ret_ str_split $i_
	}
	return ret_
}


# Usage: do normal rounding
function round(x,   ival, aval, fraction)
{
	ival = int(x)    # integer part, int() truncates

	# see if fractional part
	if (ival == x)   # no fraction
		return ival   # ensure no decimals

	if (x < 0) {
		aval = -x     # absolute value
		ival = int(aval)
		fraction = aval - ival
		if (fraction >= .5)
			return int(x) - 1   # -2.5 --> -3
		else
			return int(x)       # -2.3 --> -2
	} else {
		fraction = x - ival
		if (fraction >= .5)
			return ival + 1
		else
			return ival
	}
}


# Usage: convert string to number
# BEGIN {     # gawk test harness
#     a[1] = "25"
#     a[2] = ".31"
#     a[3] = "0123"
#     a[4] = "0xdeadBEEF"
#     a[5] = "123.45"
#     a[6] = "1.e3"
#     a[7] = "1.32"
#     a[7] = "1.32E2"
#
#     for (i = 1; i in a; i++)
#         print a[i], strtonum(a[i]), mystrtonum(a[i])
# }
function mystrtonum(str,        ret, chars, n, i, k, c)
{
	if (str ~ /^0[0-7]*$/) {
		# octal
		n = length(str)
		ret = 0
		for (i = 1; i <= n; i++) {
			c = substr(str, i, 1)
			if ((k = index("01234567", c)) > 0)
				k-- # adjust for 1-basing in awk

			ret = ret * 8 + k
		}
	} else if (str ~ /^0[xX][[:xdigit:]]+/) {
		# hexadecimal
		str = substr(str, 3)    # lop off leading 0x
		n = length(str)
		ret = 0
		for (i = 1; i <= n; i++) {
			c = substr(str, i, 1)
			c = tolower(c)
			if ((k = index("0123456789", c)) > 0)
				k-- # adjust for 1-basing in awk
			else if ((k = index("abcdef", c)) > 0)
				k += 9

			ret = ret * 16 + k
		}
	} else if (str ~ \
		/^[-+]?([0-9]+([.][0-9]*([Ee][0-9]+)?)?|([.][0-9]+([Ee][-+]?[0-9]+)?))$/) {
		# decimal number, possibly floating point
		ret = str + 0
	} else
		ret = "NOT-A-NUMBER"

	return ret
}


# getopt.awk --- Do C library getopt(3) function in awk
#
# Arnold Robbins, arnold@skeeve.com, Public Domain
#
# Initial version: March, 1991
# Revised: May, 1993

# External variables:
#    Optind -- index in ARGV of first nonoption argument
#    Optarg -- string value of argument to current option
#    Opterr -- if nonzero, print our own diagnostic
#    Optopt -- current option letter

# Returns:
#    -1     at end of options
#    "?"    for unrecognized option
#    <c>    a character representing the current option

# Private Data:
#    _opti  -- index in multi-flag option, e.g., -abc
function getopt(argc, argv, options,    thisopt, i)
{
    if (length(options) == 0)    # no options given
        return -1

    if (argv[Optind] == "--") {  # all done
        Optind++
        _opti = 0
        return -1
    } else if (argv[Optind] !~ /^-[^:[:space:]]/) {
        _opti = 0
        return -1
    }
    if (_opti == 0)
        _opti = 2
    thisopt = substr(argv[Optind], _opti, 1)
    Optopt = thisopt
    i = index(options, thisopt)
    if (i == 0) {
        if (Opterr)
            printf("%c -- invalid option\n",
                                  thisopt) > "/dev/stderr"
        if (_opti >= length(argv[Optind])) {
            Optind++
            _opti = 0
        } else
            _opti++
        return "?"
    }
    if (substr(options, i + 1, 1) == ":") {
        # get option argument
        if (length(substr(argv[Optind], _opti + 1)) > 0)
            Optarg = substr(argv[Optind], _opti + 1)
        else
            Optarg = argv[++Optind]
        _opti = 0
    } else
        Optarg = ""
    if (_opti == 0 || _opti >= length(argv[Optind])) {
        Optind++
        _opti = 0
    } else
        _opti++
    return thisopt
}

