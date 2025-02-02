	#!/bin/bash

	# [Gedit Tool]
	# Comment=Compile the current bufer
	# Name=Compile
	# Shortcut=<Control>F7
	# Applicability=all
	# Output=output-panel
	# Input=nothing

FILE_NAME=$GEDIT_CURRENT_DOCUMENT_NAME
if [ `echo $FILE_NAME | cut -d "." -f 2` = "cc" ]
then
    FILE_NAME_LEN=`expr ${#FILE_NAME} - 3`
    FILE_NAME_BASE=${FILE_NAME:0:$FILE_NAME_LEN}
    make $FILE_NAME_BASE
fi

if [ `echo $FILE_NAME | cut -d "." -f 2` = "c" ]
then
    FILE_NAME_LEN=`expr ${#FILE_NAME} - 2`
    FILE_NAME_BASE=${FILE_NAME:0:$FILE_NAME_LEN}
    make $FILE_NAME_BASE
fi

