# vim-visual-multi:

> Description.
> [More information](https://github.com/mg979/vim-visual-multi/).
> [Video](https://www.youtube.com/watch?v=N-X_zjU5INs)

# Key map

    # Enter VSM mode
        ### Re-map C-n to C-d as-Enter-VSM-mode
        ### https://github.com/mg979/vim-visual-multi/blob/master/doc/vm-mappings.txt
        Find Under            <C-d>       select the word under cursor
        Find Subword Under    <C-d>       from visual mode, without word boundaries
        Exit                  <Esc>       quit VM
        Select All            \\A         select all occurrences of a word
        Start Regex Search    \\/         create a selection with regex search
        Add Cursor At Pos     \\\         add a single cursor at current position
        Reselect Last         \\gS        reselect set of regions of last VM session

    # Special command:
        Increase              <C-A>       increase numbers (same as vim)
        Decrease              <C-X>       decrease numbers (same as vim)
        gIncrease             g<C-A>      progressively increase numbers (like |v_g_CTRL-A|)
        gDecrease             g<C-X>      progressively decrease numbers (like |v_g_CTRL-X|)
        Alpha-Increase        \\<C-A>     same but +alpha (see |'nrformats'|)

    # command:
        Transpose             \\t         transpose

        Align                 \\a         align regions
        Align Char            \\<         align by character
        Align Regex           \\>         align by regex
        One Per Line          \\L         keep at most one region per line

        Split Regions         \\s         subtract pattern from regions
        Filter Regions        \\f         filter regions by pattern/expression
        Transform Regions     \\e         transform regions with expression
        Rewrite Last Search   \\r         rewrite last pattern to match current region
        Merge Regions         \\m         merge overlapping regions
        Duplicate             \\d         duplicate regions
        Shrink                \\-         reduce regions from the sides
        Enlarge               \\+         enlarge regions from the sides
        Numbers               \\n         see |vm-numbering|
        Numbers Append        \\N         ,,

# Samples:

```c
    // Put return the same line with case, then align
    // - Enable relative number:      [or
    // - Start Regex search mode:     \\/
    // - Search ':' with newline:     /:\n
    // - Select all following:        5n
    // - Join into same line:         J
    // - Align:                       \\a
    // - Vertical insert space:       i<space>
    // - Insert space at end:         llll<space>
	switch (res) {
		case BLOCK:
			return "BLOCK";
		case ALLOW:
			return "ALLOW";
		case LOG:
			return "LOG";
		default:
			return "";
	}
```

[\ze][\zs](https://vimdoc.sourceforge.net/htmldoc/pattern.html#/%5Czs)

    :s/.*\zsabc//             ### Match the last occurrences 'abc'
    :%s/.*\zsone/two/         ### Ditto
    /\(.\{-}\zsme)\{3}        ### Match the 3nd 'me'

    How to align the follow functions | Describe text?
    - Enable relative number:                 [or
    - Start Regex search:                     \\/
    - Search the last occurrences of '()':    .*\zs()
    - Select the following several lines:     8n
    - Swap to ext-select mode:                <tab>
    - Align the select:                       \\a
    - Insert more space:                      i<space><space>

    - Rollback the change:                    '<,'>s/\s\{2,}/ /g
```md
- print, printf() and sprintf() printing functions
- length() length of an string argument
- substr() splitting string to a substring
- split() split string into an array of strings
- index() find position of an substring in a string
- sub() and gsub() (regexp) search and replace (once respectivelly globally)
- ~ operator and match() regexp search
- tolower() and toupper() convert text to lowercase resp. uppercase
```
