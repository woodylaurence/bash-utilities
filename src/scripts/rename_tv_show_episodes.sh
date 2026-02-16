#!/bin/bash

# Directories
ORIGINAL_MEDIA_DIR="$PWD/original-media"
UNMATCHED_MEDIA_DIR="$PWD/unmatched-media"
RENAMED_MEDIA_DIR="$PWD/renamed-media"

#Create media directories, if required and ensure they are empty
directories=("$ORIGINAL_MEDIA_DIR" "$UNMATCHED_MEDIA_DIR" "$RENAMED_MEDIA_DIR")
for dir in "${directories[@]}"; do
	mkdir -p "$dir"
	if [[ -n $(ls -A "$dir") ]]; then
		echo "ERROR - $dir is not empty."
		exit 1
	fi
done

#### Start in directory with media files; could be named in numerous ways
shopt -s nullglob
tv_show_media_files=()
for media_file in *.{mkv,m4v,mp4}; do
	[[ $media_file =~ S[0-9]+E[0-9]+ ]] && tv_show_media_files+=("$media_file")
done

if [[ ${#tv_show_media_files[@]} -eq 0 ]]; then
	echo "ERROR - No media files found in current directory."
	exit 1
fi

#### Move these files to a staging area
for file in "${tv_show_media_files[@]}"
do
	mv "$file" "$ORIGINAL_MEDIA_DIR/$file"
done

#### Extract series information for TV Shows
media_files_tv_info_json="[]"
for file in "${tv_show_media_files[@]}"; do
	tv_info_json=$(get-tv-info-from-filename "$file")
	media_files_tv_info_json=$(jq --argjson item "$tv_info_json" '. += [$item]' <<< "$media_files_tv_info_json")
done

#Convert list of series into unique list of search terms
tv_series_to_search_for=$(echo "$media_files_tv_info_json" | jq -r "map(.formattedSeriesName | ascii_downcase) | unique | .[] | @base64")

#Loop through series search terms, get seriesId from TVDB and then update media_files_tv_info_json to include seriesId
for encoded_series in $tv_series_to_search_for
do
	series=$(base64 --decode <<< "$encoded_series")

	#Think we're using a temporary file here because tvdb-get-series-id could output a list to choose from and we want to only capture the final output of the command?
	tmp_series_json_file=".tmp-series-json"
	tvdb-get-series-info "$series" "$tmp_series_json_file"
	IFS=$'\t' read -r series_id release_year < <(jq -r '[.seriesId, .seriesReleaseYear] | @tsv' "$tmp_series_json_file")
	rm "$tmp_series_json_file"

	media_files_tv_info_json=$(jq --arg series "$series" \
	       			      --argjson id $series_id \
				      --argjson release_year $release_year \
				      'map(if .seriesSearchTerm == $series then .seriesId = $id | .seriesReleaseYear = $release_year else . end)' \
				   <<< "$media_files_tv_info_json")
done

previous_series=""
echo "Unable to rename the following files:" > .unmatched-media-output
echo -n "Renamed the following files:" > .renamed-media-output

#### Use above information to rename files in staging area.
base64_encoded_ordered_episode_infos=$(jq  -r '. | sort_by((.formattedSeriesName | ascii_downcase), .seasonNumber, .episodeNumber) | .[] | @base64' <<< "$media_files_tv_info_json")
for encoded_episode_info in $base64_encoded_ordered_episode_infos
do
	episode_info=$(echo $encoded_episode_info | base64 --decode)
	IFS=$'\t' read -r \
		original_filename \
		series_id \
	       	series_name \
	       	series_search_term \
	       	release_year \
	       	season_number \
	       	formatted_season_number \
	       	episode_number \
		formatted_episode_number \
		extension < <(jq -r '[.filename, .seriesId, .formattedSeriesName, .seriesSearchTerm, .seriesReleaseYear,
			  	      .seasonNumber, .formattedSeasonNum, .episodeNumber, .formattedEpisodeNum, .extension] | @tsv' <<< "$episode_info")

	if [[ "$series_id" == "null" ]]; then
		ln "$ORIGINAL_MEDIA_DIR/$original_filename" "$UNMATCHED_MEDIA_DIR/$original_filename"
		echo " - $original_filename (series search term - '$series_search_term')" >> .unmatched-media-output
	else
		episode_metadata=$(tvdb-get-series-episode-details $series_id $season_number $episode_number --use-cache --update-cache)

		if [[ "$episode_metadata" == "null" ]]; then
			ln "$ORIGINAL_MEDIA_DIR/$original_filename" "$UNMATCHED_MEDIA_DIR/$original_filename"
			echo " - $original_filename (series search term - '$series_search_term')" >> .unmatched-media-output
		else
			episode_name=$(jq -r '.[0] | .name' <<< "$episode_metadata")
			
			new_filename="$series_name ($release_year) S${formatted_season_number}E${formatted_episode_number} - $episode_name.$extension"

			season_folder="$RENAMED_MEDIA_DIR/$series_name ($release_year)/Season $season_number"
			mkdir -p "$season_folder"
			ln "$ORIGINAL_MEDIA_DIR/$original_filename" "$season_folder/$new_filename"

			if [[ "$series_search_term" != "$previous_series" ]]; then
				echo >> .renamed-media-output
			fi

			echo " - $original_filename --> $new_filename ($series_name/Season $season_number)" >> .renamed-media-output

			previous_series="$series_search_term"
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
