@namespace "square"

BEGIN {
	printf("BEGIN -> square\n")
	shape::pattern_arr["square"] = "square::Init"
}

END {
	printf("END <- square\n")
}

function show()
{
	printf("Hi from square::show()\n")
}

function Init()
{
	printf("square::Inited\n")
	shape::show = "square::show"
}

