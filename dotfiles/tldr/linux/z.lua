// vim: set filetype=markdown:
z.lua
===

https://github.com/skywind3000/z.lua

# Prerequirement: lua

	# ubuntu
	$ sudo apt install lua5.2

	# fedora
	$ sudo dnf install lua

	# Append to 
	eval "$(lua ~/.z.lua/z.lua --init bash enhanced once)"

# Config for zsh base-on zplugin:

```zsh
# A command tool helps navigating faster with learning
# @note:z.lua https://github.com/skywind3000/z.lua
zplugin load skywind3000/z.lua

export _ZL_EXCLUDE_DIRS=1
export _ZL_MATCH_MODE=1  # enhanced matching mode
export _ZL_ECHO=1  # display the path after cd
export _ZL_ADD_ONCE=1  # only add path if the $PWD is changed

# alias for z.lua
alias zi="z -i"  # interactive selection
alias zb="z -b"  # jump backward
alias zh='z -I -t .'	# using fzf to search mru
```

