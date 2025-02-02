@namespace "circle"

BEGIN {
	printf("BEGIN -> circle\n")
	shape::pattern_arr["circle"] = "circle::Init"
}

END {
	printf("END <- circle\n")
}

function show()
{
	printf("Hi from circle::show()\n")
}


function Init()
{
	printf("circle::Inited\n")
	shape::show = "circle::show"
}

#ashow = show
#@show()

