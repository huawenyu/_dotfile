#!/usr/bin/awk -f
#
# $AWKPATH: please set this in your environment

@namespace "shape"
@include "libarray.awk"

# echo "hello" | ./example.awk

@include "circle.awk"
@include "square.awk"
@include "square.awk" # builtin avoid repeat include

# NOT works if not include scope {}
#array::walk_array(ENVIRON, "env")
#scriptPath2 = proc[argv][2]

BEGIN{
	# MUST put into scrope {}
	array::walk(ENVIRON, "env")
	array::walk(PROCINFO, "proc")

	scriptPath = ENVIRON["_"]
	scriptPath3 = proc[argv][2]
	printf("script=%s script2=%s script3=%s\n", scriptPath, scriptPath2, scriptPath3)

	# MUST put into scrope {}
	scriptDir = file::filedir(scriptPath)

	n = split(scriptPath, a, "/")
	#array::walk_array(a, "path")

	printf("join=%s, path=%s file=%s dir=%s\n",
			std::join(a, 1, n - 1, "/"),
			scriptPath,
			file::filename(scriptPath),
			file::filedir(scriptPath))
	pat = "hello"
}

{
	for (pattern in pattern_arr) {
		#printf("Line: %s\n", $0)

		#printf("  ? %s\n", pattern)
		if ($0 ~ pattern) {
			_init = pattern_arr[pattern]
			printf("matched %s init=%s\n", pattern, _init)
			@_init()

			@show()
			break
		}

		printf("\n-------------------------------\n")
	}
}

