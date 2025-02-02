# tagme

> Generating tags and cscope database
> [More information](https://github.com/huawenyu/zsh-local).

- create tag for C-languange, markdown files

	## Auto create into the topdir, even execute from subdir
	tagme
	tagme -a clean

	# Create `.tagx, .tags` of all Wiki markdown tags into Home
	tagme -a md

	# create softlink from the original git-repo
	tagme -a link

	# save cwd indexer into the original git-repo
	tagme -a save

	# update one tag file
	tagme -f tag-update-file

- Features:

* 1. always create tag into git-toplevel if it's git-repo,
* 2. auto detect it's our dev-dir, or markdown dir,
* 3. if it's not git-repo, create tag by default,

