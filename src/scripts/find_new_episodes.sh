#!/bin/bash

#Take input and convert to array of series
if [[ -z "$1" ]]; then
	echo "ERROR: no series provided"
	exit 1
fi

#Read the argument in as an array of series names and then alphabetically sort that list
IFS=';' read -r -a seriesArray <<< "$1"
unset IFS
IFS=$'\n' sortedSeriesArray=($(sort <<<"${seriesArray[*]}"))
unset IFS

#Loop through each series, getting series information from TVDB
for series in "${sortedSeriesArray[@]}"
do
	tmpSeriesJsonFile=".tmp-series-json"
	tvdb-get-series-id "$series" "$tmpSeriesJsonFile"
	getSeriesIdResultAsJson=$(cat "$tmpSeriesJsonFile")
	rm "$tmpSeriesJsonFile"

	seriesId=$(echo "$getSeriesIdResultAsJson" | jq -r ".seriesId")
	seriesMetaData=$(tvdb-get-series-episode-details $seriesId --ignore-cache --update-cache)

	latestEpisodeInformationForSeries=$(get-latest-episode-information-remote "$MEDIA_CENTRE_HOST" "$MEDIA_CENTRE_TV_SHOW_DIRECTORY" "$series")
	latestSeason=$(echo "$latestEpisodeInformationForSeries" | jq -c ".latestSeason")
	latestEpisode=$(echo "$latestEpisodeInformationForSeries" | jq -c ".latestEpisode")

	jqEpisodesAfterLatestEpisodeQuery="map(select(.season > $latestSeason or (.season == $latestSeason and .season > 0 and .episode > $latestEpisode)))"
	jqSortBySeasonThenEpisodeQuery="sort_by(.season, .episode)"
	episodeMetaData=$(echo "$seriesMetaData" | jq -r "$jqEpisodesAfterLatestEpisodeQuery | $jqSortBySeasonThenEpisodeQuery")

	jqAddDateStampQuery="map(. + {airDateTimestamp: .airDate | strptime(\"%Y-%m-%d\") | mktime})"
	episodeMetaDataWithTimestamps=$(echo "$episodeMetaData" | jq -r "$jqAddDateStampQuery")

	nowTimestamp=$(date +%s)
	jqEpisodeDataBeforeNowQuery="map(select(.airDateTimestamp <= $nowTimestamp))"
	encodedEpisodeMetaDataForPastEpisodes=$(echo "$episodeMetaDataWithTimestamps" | jq "$jqEpisodeDataBeforeNowQuery | .[] | @base64")
	numEpisodesAvailable=$(echo "$episodeMetaData" | jq -r "$jqEpisodeDataBeforeNowQuery | length")

	echo "$series:"
	printf '%*s\n' $((${#series} + 4)) | tr ' ' '-'

	previousEpisodeSeason=$(echo "$episodeMetaDataWithTimestamps" | jq -c ".[0].season")
	for encodedData in $encodedEpisodeMetaDataForPastEpisodes
	do
		pastEpisodeMetaData=$(echo "$encodedData" | sed 's|"||g' | base64 --decode)
		season=$(echo "$pastEpisodeMetaData" | jq -c ".season")
		episode=$(echo "$pastEpisodeMetaData" | jq -c ".episode")
		airDate=$(echo "$pastEpisodeMetaData" | jq -c ".airDate" | sed 's|"||g')
		formattedDate=$(date -d $airDate +%d/%b/%Y)

		if [[ "$season" -gt "$previousEpisodeSeason" ]]; then
			echo
		fi
		echo "Season $season Episode $episode is available (aired $formattedDate)"

		previousEpisodeSeason=$season
	done

	jqEpisodeDataForNextToAirEpisodeQuery="[.[] | select(.airDateTimestamp > $nowTimestamp)][0]"
	nextToAirEpisodeData=$(echo "$episodeMetaDataWithTimestamps" | jq -r "$jqEpisodeDataForNextToAirEpisodeQuery")

	if [[ "$nextToAirEpisodeData" == "null" ]]; then
		if [[ "$numEpisodesAvailable" -eq "0" ]]; then
			echo "No data available on next episode"
		fi
	else
		season=$(echo "$nextToAirEpisodeData" | jq -c ".season")
		episode=$(echo "$nextToAirEpisodeData" | jq -c ".episode")
		airDate=$(echo "$nextToAirEpisodeData" | jq -c ".airDate" | sed 's|"||g')
		formattedDate=$(date -d $airDate +%d/%b/%Y)

		echo "Season $season Episode $episode will air on $formattedDate"
	fi

	echo
	echo
done


#Get episodes (and seasons) greater than latest episode I have
