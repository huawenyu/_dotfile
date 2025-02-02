// vim: set filetype=markdown:
neosnippet.vim
===

https://blog.csdn.net/dark_tone/article/details/52929916

# config

```vim
    let g:neosnippet#enable_snipmate_compatibility = 1
    " The last dir will be taken as default working dir.
    let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets, ~/.vim/bundle/vim-snippets.local/snippets, '
```

# Add ourselves snippets plugins

1. create a github reps like 'huawenyu/vim-snippets.local'
  We cann't use the name like vim-snippets for which already used by `Plug 'honza/vim-snippets'`,
  so please change to another name, and the dir layout is very simple:

```sh
	vim-snippets.local git:(master) tree
		.
		├── snippets		<=== If we using neosnippet-style snippet
		│   └── _.snip		<=== The neosnippet-style take '_.snip' as 'all.snippets'
		└── UltiSnips
			├── all.snippets
			├── c.snippets
```
2. Add the dir to neosnippet:

```vim
    " The last dir will be taken as default working dir.
    let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets, ~/.vim/bundle/vim-snippets.local/snippets, '
```

## Live edit snippets

```vim
	:NeoSnippetEdit 		<=== Live edit the current <filetype>.snip
	:NeoSnippetEdit c		<=== Live edit the c.snip
	:NeoSnippetEdit _		<=== Live edit the existed all snippets.
```

