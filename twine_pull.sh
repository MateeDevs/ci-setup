#!/bin/bash
if [ -d "$TWINE_FOLDER" ]; 
	then git -C $TWINE_FOLDER pull origin master; 
	else git clone "git@github.com:MateeDevs/twine-localization.git" $TWINE_FOLDER;
fi
