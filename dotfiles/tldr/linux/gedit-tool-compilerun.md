	#!/bin/bash

	# [Gedit Tool]
	# Comment=Compile and Run current buffer
	# Name=Compile Run
	# Shortcut=<Control>F8
	# Applicability=all
	# Output=output-panel
	# Input=nothing

FILE_NAME=$GEDIT_CURRENT_DOCUMENT_NAME
if [ `echo $FILE_NAME | cut -d "." -f 2` = "cc" ]
then
    FILE_NAME_LEN=`expr ${#FILE_NAME} - 3`
    FILE_NAME_BASE=${FILE_NAME:0:$FILE_NAME_LEN}
    make $FILE_NAME_BASE
    if [ -r $FILE_NAME_BASE.in ]
    then
        echo "Running"
        ./$FILE_NAME_BASE < $FILE_NAME_BASE.in
    else
        echo "Input file not found"
    fi
fi

if [ `echo $FILE_NAME | cut -d "." -f 2` = "c" ]
then
    FILE_NAME_LEN=`expr ${#FILE_NAME} - 2`
    FILE_NAME_BASE=${FILE_NAME:0:$FILE_NAME_LEN}
    make $FILE_NAME_BASE
    if [ -r $FILE_NAME_BASE.in ]
    then
        echo "Running"
        ./$FILE_NAME_BASE < $FILE_NAME_BASE.in
    else
        echo "Input file not found"
    fi
fi

if [ `echo $FILE_NAME | cut -d "." -f 2` = "py" ]
then
    python $FILE_NAME
fi

if [ `echo $FILE_NAME | cut -d "." -f 2` = "sh" ]
then
    sh $FILE_NAME
fi

if [ `echo $FILE_NAME | cut -d "." -f 2` = "pl" ]
then
    perl $FILE_NAME
fi
