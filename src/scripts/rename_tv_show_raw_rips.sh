#!/bin/bash

WORK_DIR="/mnt/Dump/RawRips/TV Shows"
RENAMED_MARKER_FILE_NAME=".renamed"

cd "$WORK_DIR"

for seriesFolder in *
do
	echo
	echo
	
	pushd "$seriesFolder" > /dev/null

	for seasonFolder in *
	do
		if [[ -e "$seasonFolder/$RENAMED_MARKER_FILE_NAME" ]]; then
			echo "Already renamed file in $seriesFolder/$seasonFolder"
			continue
		fi

		SEASON_NUMBER_REGEX="^.*Season([0-9]+)_(DVD|BluRay)Rip$"
		seasonNumber=$(sed -nr "s/$SEASON_NUMBER_REGEX/\1/p" <<< "$seasonFolder")
		if [[ -z "$seasonNumber" ]]; then
			echo "Could not parse season number for ${seriesFolder}-${seasonFolder}"
			continue
		fi

		seasonNumber=$(printf %02d $seasonNumber)
		pushd "$seasonFolder" > /dev/null

		i=1
		for discFolder in */
		do
			DISC_REGEX="Disc[0-9]+"
			if [[ ! "$discFolder" =~ $DISC_REGEX ]]; then
				echo "Could not find Disc folder"
				continue
			fi

			pushd "$discFolder" > /dev/null
			for episodeFile in *.mkv
			do
				formattedEpisodeNumber=$(printf %02d $i)

				echo "Renaming $episodeFile --> ${seriesFolder}_S${seasonNumber}E${formattedEpisodeNumber}.mkv"
				mv "$episodeFile" "${seriesFolder}_S${seasonNumber}E${formattedEpisodeNumber}.mkv"
				i=$((i + 1))
			done

			popd > /dev/null
		done

		mv Disc*/*.mkv ./
		rmdir Disc*

		touch $RENAMED_MARKER_FILE_NAME
		echo "Renamed episodes in $seasonFolder"

		popd > /dev/null
	done

	popd > /dev/null
done
