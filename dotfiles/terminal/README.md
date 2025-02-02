
# bash/zsh

	### get a list of shortcuts...look for the "clear-screen" on. By default it should be set to "C-l"
	### Should out of tmux
	$ bind-key -P

	### get current key's hex value
	### Should out of tmux
	$ showkey -a

# Windows 10/11

## screen snip

Select the Start, enter `snipping tool`, then select Snipping Tool from the results.

Press Windowskey + Shift + S.

## Best terminal microsoft-terminal

Install from https://github.com/microsoft/terminal

- Mobaxterm (support multiple tab-window, change font: Ctrl-scroll, support protocol like mosh)
  + Can't support R_Alt + number: tmux select windows
  + mouse scroll:
    - in vim, like up/down the cursor, not the screen
    - out of vim, like shell, behavour like up/down different commands, not turn into tmux-copy-mode and scroll the whole screen
  + mouse select by double left-click is weird, can't auto-deletect word boundry
- Alacritty (config flexible & powerful & loading runtime, best terminal under linux, but not microsoft-windows 10)
  + [A config sample](https://github.com/tmcdonell/config-alacritty/blob/master/alacritty.yml)
  + mouse support not good:
    - vim can't click select window
    - tmux can't click select window, only works by shortcuts: Alt+number
  + Under vim, Ctrl-L cause the screen flash, even not works after disable the bash/zsh shell bind-key Ctrl-L: clear-screen

- Kitty (from putty, so far it's good)
  + [config unix/linux sample](https://sw.kovidgoyal.net/kitty/conf/#font-sizes)
  + #Can't map the change font-size shortcusts
  + Don't support ProxyJump/mosh, since all ssh implement by itself, but perfer inside WSL(ubuntu 20.04), then use ssh to access remote

- Microsoft-terminal
  + [O] almost don't need config,
  + [O] shortcusts support select tab,
  + [O] Using WSL, so everything doing inside WSL-ubuntu like ssh ProxyJump/mosh, and configgable by ~/.ssh/config

## Microsoft terminal

- Disable: Warn when the text to paste contains multiple lines

  Hold down the `Shift` key while selecting Settings in the Windows Terminal dropdown menu.
    This will open the editor associated with json files `settings.json`, change as:

	"multiLinePasteWarning": false,
- Select auto-to clipboard

	Setting->Interaction->Automatically copy selection to clipboard=On

