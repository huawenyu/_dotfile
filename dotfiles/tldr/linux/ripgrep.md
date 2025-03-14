# ripgrep:

```bash
    ### Search all files
    rg -uuu --glob='*' -w "somewords"
        # --glob='*'      Forces ripgrep to include all files by matching everything.
        # -uuu            Ensures that all ignore rules are bypassed, hidden files are included, and binary files are searched.

    ### Like:
    grep -Inr "somewords" .
```

> better grep

```bash
	## Seach recursively under current dir
	rg <text>
	## Seach recursively under(or not) dir
	rg <text> dir/
	rg <text> dir1 dir2
	rg <text> -g '!dir1/' -g '!dir2/'
	## Seach in a single file
	rg <text> <one-file>
	## Seach in(or-not) certain files
	rg <text> -g '*.c'
	rg <text> -g '!*.c'
	## Only(or-inverse) show matched file-name
	rg -l <text>
	rg -v <text>
```

- With option:

```bash
	## Ignorecase
	rg -i <text>
	## Literally: not regex
	rg -F '(test)'
	## the whole word
	rg -w 'test'
	## show the number of matching lines
	rg --count 'test'
	## show the search stats
	rg --stats 'test'
```

- Issues:

	## [line number disappear when piping command #796](https://github.com/BurntSushi/ripgrep/issues/796)
	`--column` will also force show line+column even with piping
