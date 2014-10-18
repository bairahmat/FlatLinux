#!/bin/bash
echo -en "Note: the system requirements to install FlatLinux are the following:\nBash-3.2\nBinutils-2.17 (versions greater than 2.24 are not recommended because they have not been tested)\nBison-2.3 (/usr/bin/yacc should be a link to Bison)\nBzip2-1.0.4\nCoreutils-6.9\nDiffutils-2.8.1\nFindutils-4.2.31\nGawk-4.0.1 (/usr/bin/awk should be a link to Gawk)\nGCC-4.1.2 including g++ (versions greater than 4.9.1 are not recommended as they have not been tested)\nGlibc-2.5.1 (versions greater than 2.20 are not recommended because they have not been tested)\nGrep-2.5.1a\nGzip-1.3.12\nLinux Kernel-2.6.32\nM4-1.4.10\nMake-3.81\nPatch-2.5.4\nPerl-5.8.8\nSed-4.1.5\nTar-1.18\nXz-5.0.0\nYou will need to manually check these dependicies before continuing.\nContinue? (y/n)"
read CONTINUE
if [ "$CONTINUE" = "n" ]
then
	exit
fi
echo -en "Which device would you like to install FlatLinux on?"
read DEVICE
echo "Where is $DEVICE mounted? Press enter if it is not mounted."
read LOC
if [ "$LOC" = "" ]
then
	echo "Where would you like to mount $DEVICE?"
	read LOC
	echo "Attempting to mount ${DEVICE}..."
	MOUNTERR=`mount $DEVICE $LOC`
	if [ "$?" -ne "0" ]
	then
		echo "Error occurred mounting $DEVICE with error code ${?}."
		exit
	fi
fi
