#!/usr/bin/awk -f
#
# Usage: cat num.list | upper.awk -v t=180
BEGIN {
	idx = 0;
	CHK_MAX = 3;
	for (i=0; i < CHK_MAX; ++i) {
		win_lines[i] = "????";
	}
}

{
	if (NF >= 1) {
		idx += 1
		idx = idx % CHK_MAX
		win_lines[idx] = $0

		for (i=0; i < CHK_MAX; ++i) {
			if (i != idx) {
				if ($0 == win_lines[i]) {
					print FILENAME ":" FNR "  " $0
				}
			}
		}
	}

}

END{
}
