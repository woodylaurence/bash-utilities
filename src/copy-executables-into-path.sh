#!/bin/bash

interactiveCopy=true
while getopts ":f" opt
do
	case $opt in
		f )
			interactiveCopy=false
	esac
done
shift $((OPTIND-1))

if [[ -n "$1" ]]; then
	echo "Copying $1 into path directory..."
	if $interactiveCopy ;then
		sudo cp -i "$1" /usr/local/bin
	else
		sudo cp "$1" /usr/local/bin
	fi
	echo "Done"
else
	echo "Copying utility files into path directory..."
	pushd utilities > /dev/null
	if $interactiveCopy ;then
		sudo cp -i * /usr/local/bin
	else
		sudo cp * /usr/local/bin
	fi
	popd > /dev/null
	echo "Done"

	echo
	echo "Copying script files into path directory..."
	pushd scripts > /dev/null
	if $interactiveCopy ;then
		sudo cp -i * /usr/local/bin
	else
		sudo cp * /usr/local/bin
	fi
	popd > /dev/null
	echo "Done"
fi
