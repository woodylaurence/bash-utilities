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

copy_with_interactive_check() {
	if $interactiveCopy; then
		sudo cp -i "$@"
	else
		sudo cp "$@"
	fi
}

if [[ -n "$1" ]]; then
	echo "Copying $1 into path directory..."
	copy_with_interactive_check "$1" /usr/local/bin
	echo "Done"
else
	echo "Copying utility files into path directory..."
	copy_with_interactive_check utilities/* /usr/local/bin
	echo Done

	echo "Copying script files into path directory..."
	copy_with_interactive_check scripts/*.sh /usr/local/bin
	copy_with_interactive_check scripts/encode_rips_completions.bash /etc/bash_completion.d/encode_rips
	echo "Done"
fi