# Doc
https://github.com/tldr-pages/tldr-python-client

	$ pip3 install tldr
	$ export TLDR_PAGES_SOURCE_LOCATION=file://$HOME/dotfiles/tldr
	$ pwd
		/home/hyu/dotfiles/tldr/
	$ tree
		.
		└── linux
		    └── test1.md
	$ tldr test1

# How to write ourself pages

https://github.com/tldr-pages/tldr/blob/main/CONTRIBUTING.md

Detail: https://github.com/tldr-pages/tldr/blob/main/contributing-guides/style-guide.md

## Subcommands
Many programs use subcommands for separating functionality, which may require their own separate pages.
For instance, git commit has its own page, as well as git push and many others.
To create a page for a subcommand, the program and subcommand need to be separated with a dash
(-), so `git-commit.md` is shown when calling `tldr git commit`.
