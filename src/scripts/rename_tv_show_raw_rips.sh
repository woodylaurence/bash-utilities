#!/bin/bash

WORK_DIR="/mnt/Dump/RawRips/TV Shows"
RENAMED_MARKER_FILE_NAME=".renamed"

cd "$WORK_DIR"

for series_name in *
do
	echo
	echo

	if [[ $series_name =~ ^[a-zA-Z0-9]+$ ]]; then
		echo "Looking at $series_name"
	else
		echo "Warning - can't parse series name from $series_name. Skipping..."
		continue
	fi
	
	pushd "$series_name" > /dev/null

	for season_folder in *
	do
		if [[ -e "$season_folder/$RENAMED_MARKER_FILE_NAME" ]]; then
			echo "Already renamed file in $series_name/$season_folder"
			continue
		fi

		SEASON_NUMBER_REGEX="^Season([0-9]+)$"
		if [[ $season_folder =~ $SEASON_NUMBER_REGEX ]]; then
			season_number=${BASH_REMATCH[1]}
		else
			echo "Warning - Could not parse season number for $series_name / $season_folder"
			continue
		fi

		formatted_season_number=$(printf %02d $season_number)
		pushd "$season_folder" > /dev/null

		i=1
		for disc_folder in */
		do
			DISC_REGEX="Disc[0-9]+"
			if [[ ! "$disc_folder" =~ $DISC_REGEX ]]; then
				echo "Could not find Disc folder"
				continue
			fi

			pushd "$disc_folder" > /dev/null
			for episode_file in *.mkv
			do
				formatted_episode_number=$(printf %02d $i)

				echo "Renaming $episode_file --> ${series_name}_S${formatted_season_number}E${formatted_episode_number}.mkv"
				mv "$episode_file" "${series_name}_S${formatted_season_number}E${formatted_episode_number}.mkv"
				i=$((i + 1))
			done

			popd > /dev/null
		done

		mv Disc*/*.mkv ./
		rmdir Disc*

		touch $RENAMED_MARKER_FILE_NAME
		echo "Renamed episodes in $season_folder"

		popd > /dev/null
	done

	popd > /dev/null
done
