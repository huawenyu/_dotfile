# tldr: short/better man/doc

> My dotfiles/script/tldr
> Original: <https://raw.githubusercontent.com/tldr-pages/tldr-python-client/main/tldr.py>.

# setup

	### add to shell-profile
	export TLDR_PAGES_SOURCE_LOCATION="https://raw.githubusercontent.com/tldr-pages/tldr/master/pages; file://$HOME/dotwiki/tldr; file://$HOME/wiki/tldr; file://$HOME/dotfiles/tldr"

# Sample with option:

	# List all command
	tldr -l
	# List all page source
	tldr -a
	# Special platform, language(default = en)
	tldr -p linux common -L en
	# Edit a entry
	tldr -e <entry>

# Features:
! [This is hidden comment](https://github.com/huawenyu/dotfiles/script/tldr)

## feature List
Must begin with [<space>{1,}][-*+]:
  * support multiple page sources:
    - has priority: local -> remote,
    - filter show/edit by option `-i`, e.g. `-i dotfile`
    - default is go-through all of them
  * support edit(vi) mode by option `-e`:
    - only limit in local file source
    - if the enty not exist, auto create a template-local-file
  * support mutiple syntax:
    - syntax-fence beginwith/endwith "\`\`\`"
    - syntax-block beginwith <tab>
    - syntax-block-comment beginwith `<tab>#`
    - syntax-list beginwith <space>[-*+]
    - syntax-comment beginwith '!', which will be hidden in output

