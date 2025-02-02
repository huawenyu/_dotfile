// vim: set filetype=markdown:
fzf.vim
===

# config

## config color

### method-1 [good: from vimrc]

    " Customize fzf colors to match your color scheme
    let g:fzf_colors =
    \ { 'fg':      ['fg', 'Normal'],
      \ 'bg':      ['bg', 'Normal'],
      \ 'hl':      ['fg', 'Function'],
      \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
      \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
      \ 'hl+':     ['fg', 'Statement'],
      \ 'info':    ['fg', 'PreProc'],
      \ 'border':  ['fg', 'Ignore'],
      \ 'prompt':  ['fg', 'Conditional'],
      \ 'pointer': ['fg', 'Exception'],
      \ 'marker':  ['fg', 'Keyword'],
      \ 'spinner': ['fg', 'Label'],
      \ 'header':  ['fg', 'Comment'] }

    " Enable per-command history.
    " CTRL-N and CTRL-P will be automatically bound to next-history and
    " previous-history instead of down and up. If you don't like the change,
    " explicitly bind the keys to down and up in your $FZF_DEFAULT_OPTS.
    let g:fzf_history_dir = '~/.local/share/fzf-history'

### method-2 [bad: zshrc]

https://jonasjacek.github.io/colors/

Append this to our bashrc/zshrc:

```bash

export FZF_DEFAULT_OPTS='
--color fg:-1,bg:-1,hl:178,fg+:3,bg+:233,hl+:220
--color info:150,prompt:110,spinner:150,pointer:167,marker:174
'
```

So here the color use 'Xterm Number'

```vim
Display 	 Xterm Number 	 Xterm Name     	 HEX     	 RGB        	 HSL
color   	 178          	 Black (SYSTEM) 	 #000000 	 rgb(0,0,0) 	 hsl(0,0%,0%)
```

## Config Keys

Use different keys to navigate between matched candidates.
Append this to our bashrc/zshrc:

```bash
export FZF_DEFAULT_OPTS='--bind=ctrl-p:up,ctrl-n:down'
```

So with color together, should like:


```bash
export FZF_DEFAULT_OPTS='
--bind=ctrl-p:up,ctrl-n:down
--color fg:-1,bg:-1,hl:178,fg+:3,bg+:233,hl+:220
--color info:150,prompt:110,spinner:150,pointer:167,marker:174
'
```

## Everything call `fzf#vim#grep`

So use awk to control the ouput columns and [color](https://stackoverflow.com/questions/14482101/awk-adding-color-code-to-text/47873421):

```vim
	let command = 'cat ./.cscope.files'. "| awk '($1~/". a:args . "/) {print $0\":\033[30m0:0:0\033[0m\"}' "
	call fzf#vim#grep(
		\   command, 1,
		\   a:preview ? fzf#vim#with_preview('up:60%')
		\           : fzf#vim#with_preview('right:50%:hidden', '?'),
		\   a:preview)
```

### awk with colors

```awk
function isnumeric(x)
{
    return ( x == x+0 );
}

function name_to_number(name, predefined)
{
    if (isnumeric(name))
        return name;

    if (name in predefined)
        return predefined[name];

    return name;
}

function colour(v1, v2, v3)
{
    if (v3 == "" && v2 == "" && v1 == "")
        return;

    if (v3 == "" && v2 == "")
        return sprintf("%c[%dm", 27, name_to_number(v1, fgcolours));
    else if (v3 == "")
        return sprintf("%c[%d;%dm", 27, name_to_number(v1, bgcolours), name_to_number(v2, fgcolours));
    else
        return sprintf("%c[%d;%d;%dm", 27, name_to_number(v1, attributes), name_to_number(v2, bgcolours), name_to_number(v3, fgcolours));
}

BEGIN {
    # hack to use attributes for just "None"
    fgcolours["None"] = 0;

    fgcolours["Black"] = 30;
    fgcolours["Red"] = 31;
    fgcolours["Green"] = 32;
    fgcolours["Yellow"] = 33;
    fgcolours["Blue"] = 34;
    fgcolours["Magenta"] = 35;
    fgcolours["Cyan"] = 36;
    fgcolours["White"] = 37;

    bgcolours["Black"] = 40;
    bgcolours["Red"] = 41;
    bgcolours["Green"] = 42;
    bgcolours["Yellow"] = 43;
    bgcolours["Blue"] = 44;
    bgcolours["Magenta"] = 45;
    bgcolours["Cyan"] = 46;
    bgcolours["White"] = 47;

    attributes["None"] = 0;
    attributes["Bold"] = 1;
    attributes["Underscore"] = 4;
    attributes["Blink"] = 5;
    attributes["ReverseVideo"] = 7;
    attributes["Concealed"] = 8;
}

{
    print colour("Red")$1colour("Blue")$0colour("None");
}
```

# Commands

:Files      is for finding files by name. I used to use Ctrl-P for this, but FZF is so much better and quicker that I ditched Ctrl-P almost immediately (though you can map :Files to it if you want to use the same key).
:Rg         uses Ripgrep to search for content in files, so you can search for a specific string. This makes it an excellent replacement for the Ggrep command from Fugitive.
:Snippets   works with Ultisnips to provide a filterable list of available snippets you can insert, making it much more useful
:Tags       allows you to filter and search tags in the project as a whole
:BTags      does the same, but solely in the current buffer
:Lines      allows you to find lines in the project and navigate to them.
:BLines     does the same, but solely in the current buffer.

