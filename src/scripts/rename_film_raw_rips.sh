#!/bin/bash

WORK_DIR="/mnt/dump/RawRips/Films"
RENAMED_MARKER_FILE_NAME=".renamed"

for dir in "$WORK_DIR"/*/
do
	film_name=$(basename "$dir")

	if [[ -e "$dir/$RENAMED_MARKER_FILE_NAME" ]]; then
		echo "Already renamed file in $film_name"
		continue
	fi

	num_files_in_folder=$(ls "$dir" -1 | wc -l)
	if [[ $num_files_in_folder -gt 1 ]]; then
		echo "$dir has more than 1 file in, please sort out manually."
		continue;
	fi

	mv "$dir"*.mkv "$dir${film_name}.mkv"
	touch "${dir}${RENAMED_MARKER_FILE_NAME}"
	echo "Renamed file in $film_name"
done
