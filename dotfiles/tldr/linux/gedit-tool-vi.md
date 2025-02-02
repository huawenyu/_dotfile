	#!/bin/sh

	# [Gedit Tool]
	# Comment=Open the file by vim
	# Name=Open with vim
	# Shortcut=F5
	# Applicability=all
	# Output=nothing
	# Input=nothing

	#TODO: use "gconftool-2 -g /desktop/gnome/applications/terminal/exec"
	#gnome-terminal  --working-directory=$GEDIT_CURRENT_DOCUMENT_DIR -- /usr/bin/python3 "$GEDIT_CURRENT_DOCUMENT_PATH"
exo-open --launch TerminalEmulator bash -c "vim $GEDIT_CURRENT_DOCUMENT_PATH"

