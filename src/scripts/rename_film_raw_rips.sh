#!/bin/bash

# WORK_DIR="/mnt/Dump/RawRips/Films"
WORK_DIR="/home/laurence/test"
RENAMED_MARKER_FILE_NAME=".renamed"

cd "$WORK_DIR"

for filmFolder in *
do
	if [[ -e "$filmFolder/$RENAMED_MARKER_FILE_NAME" ]]; then
		echo "Already renamed file in $filmFolder"
		continue
	fi

	numFilesInFolder=$(ls "$filmFolder" -1 | wc -l)
	if [[ $numFilesInFolder -gt 1 ]]; then
		echo "$filmFolder has more than 1 file in, please sort out manually."
		continue;
	fi

		FILM_NAME_REGEX="^(.*)_(DVD|BluRay)Rip$"
		filmName=$(sed -r "s/$FILM_NAME_REGEX/\1/" <<< "$filmFolder")
		if [[ -z "$filmName" ]]; then
		echo "Woah, could get film name from $filmFolder based on regex...Skipping."
		continue
	fi

	pushd "$filmFolder" > /dev/null
	mv ./*.mkv "${filmName}.mkv"
	touch .renamed

	echo "Renamed file in $filmFolder"

	popd > /dev/null
done
