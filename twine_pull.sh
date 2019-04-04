#!/bin/bash
#[[ -d $TWINE_FOLDER ]] || mkdir -p $TWINE_FOLDER
if [ -d "$TWINE_FOLDER" ]; 
	then git -C $TWINE_FOLDER pull origin master; 
	else git clone "ssh://qest@vs-ssh.visualstudio.com:22/DefaultCollection/Qest/_ssh/twine-localization" $TWINE_FOLDER;
fi
