# GUI editor geany (better alter: gedit)

> A better gedit/xedit: support open-file-in-vim/vim-mode
> More information: <https://www.geany.org/>.

- Install:

	sudo apt install geany geany-plugins

- Open file in vim:

* 1. GUI>>Tools>>Plugin Manager, Enable the File Browser.
* 2. GUI>>Tools>>Plugin Manager, mouse-select `File Browser`, click `Plugin Preferences`,
*    you should see a field titled External Open Command which defaults to

	nautilus "%d"

* Ubuntu, change the line to:

	gnome-terminal --working-directory="%d"

* Xubuntu, change the line to:
. [ref](https://askubuntu.com/questions/1215533/how-to-write-commands-with-default-variables-for-terminal-or-default-app-browse)

	exo-open --launch TerminalEmulator bash -c 'vim "%f"'

- Color theme: download from [Themes](https://www.geany.org/download/themes/)

	# The `$_` is a special parameter that holds the last argument of the previous command.
	# The quote around $_ make sure it works even if the folder name contains spaces.

	$ mkdir -p ~/.config/geany/colorschemes/ && cd "$_"

	## copy the link from [Button-Download], then:

	$ wget <the-link>

	## Then GUI>>View>>Change Color Sheme, choose the new downloaded scheme.

 
