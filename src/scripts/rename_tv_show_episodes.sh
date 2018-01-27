#!/bin/bash

# Directories
ORIGINAL_MEDIA_DIR="$PWD/original-media"
UNMATCHED_MEDIA_DIR="$PWD/unmatched-media"
RENAMED_MEDIA_DIR="$PWD/renamed-media"

#Ensure the current directory doesn't already have outstanding renaming output
if [[ -e "$ORIGINAL_MEDIA_DIR" ]]; then
	echo "ERROR: original-media folder exists in current directory."
	exit 1
fi
if [[ -e "$UNMATCHED_MEDIA_DIR" ]]; then
	echo "ERROR: unmatched-media folder exists in current directory."
	exit 1
fi
if [[ -e "$RENAMED_MEDIA_DIR" ]]; then
	echo "ERROR: renamed-media folder exists in current directory."
	exit 1
fi

#### Start in directory with media files; could be named in numerous ways
shopt -s nullglob
allMediaFiles=(*.{mkv,m4v,mp4,avi})

if [[ ${#allMediaFiles[@]} -eq 0 ]]; then
	echo "ERROR: No media files found in current directory."
	exit 1
fi

#Make Directories
mkdir "$ORIGINAL_MEDIA_DIR"
mkdir "$UNMATCHED_MEDIA_DIR"
mkdir "$RENAMED_MEDIA_DIR"

#### Copy (link to save time) these files to a staging area and rename to standard format
for file in "${allMediaFiles[@]}"
do
	mv "$file" "$ORIGINAL_MEDIA_DIR/$file"
done

#### Extract series information for TV Shows
mediaFilesTvInfoJson="[]"
for file in "${allMediaFiles[@]}"
do
	tvInfoJson=$(get-tv-info-from-filename "$file")
	jqAppendToArrayQuery=". += [$tvInfoJson]"
	mediaFilesTvInfoJson=$(echo "$mediaFilesTvInfoJson" | jq "$jqAppendToArrayQuery")
done

#Convert list of series into unique list of search terms
jqSeriesNameQuery="map(.formattedSeriesName | ascii_downcase) \
						| unique \
						| .[]
						| @base64"
tvSeriesToSearchFor=$(echo "$mediaFilesTvInfoJson" | jq -r "$jqSeriesNameQuery")

#Loop through series earch terms, get seriesId from TVDB and then update mediaFilesTvInfoJson to include seriesId
for encodedSeries in $tvSeriesToSearchFor
do
	series=$(echo "$encodedSeries" | base64 --decode)

	tmpSeriesJsonFile=".tmp-series-json"
	tvdb-get-series-id "$series" "$tmpSeriesJsonFile"
	getSeriesIdResultAsJson=$(cat "$tmpSeriesJsonFile")
	rm "$tmpSeriesJsonFile"

	seriesId=$(echo "$getSeriesIdResultAsJson" | jq -r ".seriesId")
	jqUpdateSeriesIdQuery="map((select(.seriesSearchTerm == \"$series\") | .seriesId) |= $seriesId)"
	mediaFilesTvInfoJson=$(echo "$mediaFilesTvInfoJson" | jq -r "$jqUpdateSeriesIdQuery")
done

previousSeries=""
echo "Unable to rename the following files:" > .unmatched-media-output
echo -n "Renamed the following files:" > .renamed-media-output

#### Use above information to rename files in staging area.
jqSortBySeriesNameThenSeasonThenEpisodeQuery=". | sort_by((.formattedSeriesName | ascii_downcase), .seasonNumber, .episodeNumber)"
for encodedEpisodeInfo in $(echo "$mediaFilesTvInfoJson" | jq -r "$jqSortBySeriesNameThenSeasonThenEpisodeQuery | .[] | @base64")
do
	episodeInfo=$(echo $encodedEpisodeInfo | base64 --decode)
	seriesId=$(echo "$episodeInfo" | jq -r ".seriesId")
	originalFilename=$(echo "$episodeInfo" | jq -r ".filename")
	seriesSearchTerm=$(echo "$episodeInfo" | jq ".seriesSearchTerm" | sed 's/"//g')

	if [[ "$seriesId" == "null" ]]; then
		ln "$ORIGINAL_MEDIA_DIR/$originalFilename" "$UNMATCHED_MEDIA_DIR/$originalFilename"
		echo " - $originalFilename (series search term - '$seriesSearchTerm')" >> .unmatched-media-output
	else
		seasonNumber=$(echo "$episodeInfo" | jq -r ".seasonNumber")
		episodeNumber=$(echo "$episodeInfo" | jq -r ".episodeNumber")

		episodeMetaData=$(tvdb-get-series-episode-details $seriesId $seasonNumber $episodeNumber --use-cache --update-cache)

		if [[ "$episodeMetaData" == "null" ]]; then
			ln "$ORIGINAL_MEDIA_DIR/$originalFilename" "$UNMATCHED_MEDIA_DIR/$originalFilename"
			echo " - $originalFilename (series search term - '$seriesSearchTerm')" >> .unmatched-media-output
		else
			episodeName=$(echo "$episodeMetaData" | jq ".[0] | .name")
			formattedEpisodeNumber=$(echo "$episodeInfo" | jq ".formattedEpisodeNum")
			fileExtension=$(echo "$episodeInfo" | jq ".extension")
			newFileName=$(echo "$formattedEpisodeNumber $episodeName.$fileExtension" | sed 's/"//g')

			seriesName=$(echo "$episodeInfo" | jq ".formattedSeriesName" | sed 's/"//g')
			episodeFolder="$RENAMED_MEDIA_DIR/$seriesName/Season $seasonNumber"
			mkdir -p "$episodeFolder"
			ln "$ORIGINAL_MEDIA_DIR/$originalFilename" "$episodeFolder/$newFileName"

			if [[ "$seriesSearchTerm" != "$previousSeries" ]]; then
				echo >> .renamed-media-output
			fi

			echo " - $originalFilename --> $newFileName ($seriesName/Season $seasonNumber)" >> .renamed-media-output

			previousSeries="$seriesSearchTerm"
		fi
	fi
done

if [[ $(wc -l < .renamed-media-output) -gt "1" ]]; then
	echo
	echo
	cat .renamed-media-output
	echo "--------------------------------------------"
	echo
fi

if [[ $(wc -l < .unmatched-media-output) -gt "1" ]]; then
	if [[ $(wc -l < .renamed-media-output) -le "1" ]]; then
		echo
		echo
	fi
	cat .unmatched-media-output
	echo "--------------------------------------------"
fi

rm .renamed-media-output
rm .unmatched-media-output

#### Display renames to user, accept or deny
