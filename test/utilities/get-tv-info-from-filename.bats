#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load
load ../helpers/custom-assert-helpers

ORIGINAL_PATH_VARIABLE=$PATH

setup() {
	PATH=PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"
}

@test "1 - get-tv-info-from-filename: filename doesnt have series name" {
	fakeFilename="S01E01.mkv"
	run get-tv-info-from-filename $fakeFilename

	assert_failure
	assert_output "ERROR - Filename '$fakeFilename' cannot be parsed as TV episode."
}

@test "2 - get-tv-info-from-filename: filename has invalid or missing season number" {
	fileNameWithMissingSeasonIdentifier="StarTrek_E01.mkv"
	run get-tv-info-from-filename $fileNameWithMissingSeasonNumber

	assert_failure
	assert_output "ERROR - Filename '$fileNameWithMissingSeasonNumber' cannot be parsed as TV episode."

	fileNameWithMissingSeasonNumber="StarTrek_SE01.mkv"
	run get-tv-info-from-filename $fileNameWithMissingSeasonNumber

	assert_failure
	assert_output "ERROR - Filename '$fileNameWithMissingSeasonNumber' cannot be parsed as TV episode."

	fileNameWithNonNumericSeasonNumber="StarTrek_SfE01.mkv"
	run get-tv-info-from-filename $fileNameWithNonNumericSeasonNumber

	assert_failure
	assert_output "ERROR - Filename '$fileNameWithNonNumericSeasonNumber' cannot be parsed as TV episode."
}

@test "3 - get-tv-info-from-filename: filename has invalid or missing episode number" {
	fileNameWithMissingEpisodeIdentifier="StarTrek_S01.mkv"
	run get-tv-info-from-filename $fileNameWithMissingEpisodeIdentifier

	assert_failure
	assert_output "ERROR - Filename '$fileNameWithMissingEpisodeIdentifier' cannot be parsed as TV episode."

	fileNameWithMissingEpisodeNumber="StarTrek_S01E.mkv"
	run get-tv-info-from-filename $fileNameWithMissingEpisodeNumber

	assert_failure
	assert_output "ERROR - Filename '$fileNameWithMissingEpisodeNumber' cannot be parsed as TV episode."

	fileNameWithNonNumericSeasonNumber="StarTrek_S01Ej.mkv"
	run get-tv-info-from-filename $fileNameWithNonNumericSeasonNumber

	assert_failure
	assert_output "ERROR - Filename '$fileNameWithNonNumericSeasonNumber' cannot be parsed as TV episode."
}

@test "4 - get-tv-info-from-filename: filename has single digit season" {
	run get-tv-info-from-filename "Psych_S1E19.mkv"

	assert_success
	assert_json_equal "$output" '{
		"filename": "Psych_S1E19.mkv",
		"seriesId": null,
		"seriesName": "Psych",
		"formattedSeriesName": "Psych",
		"seriesSearchTerm": "psych",
		"seriesReleaseYear": null,
		"seasonNumber": 1,
		"formattedSeasonNum": "01",
		"episodeNumber": 19,
		"formattedEpisodeNum": "19",
		"extension": "mkv"
	}'
}

@test "5 - get-tv-info-from-filename: filename has two digit season" {
	run get-tv-info-from-filename "Psych_S01E19.mkv"

	assert_success
	assert_json_equal "$output" '{
		"filename": "Psych_S01E19.mkv",
		"seriesId": null,
		"seriesName": "Psych",
		"formattedSeriesName": "Psych",
		"seriesSearchTerm": "psych",
		"seriesReleaseYear": null,
		"seasonNumber": 1,
		"formattedSeasonNum": "01",
		"episodeNumber": 19,
		"formattedEpisodeNum": "19",
		"extension": "mkv"
	}'

	run get-tv-info-from-filename "Psych_S14E19.mkv"

	assert_success
	assert_json_equal "$output" '{
		"filename": "Psych_S14E19.mkv",
		"seriesId": null,
		"seriesName": "Psych",
		"formattedSeriesName": "Psych",
		"seriesSearchTerm": "psych",
		"seriesReleaseYear": null,
		"seasonNumber": 14,
		"formattedSeasonNum": "14",
		"episodeNumber": 19,
		"formattedEpisodeNum": "19",
		"extension": "mkv"
	}'
}

@test "6 - get-tv-info-from-filename: filename has zero season number" {
	run get-tv-info-from-filename "Psych_S0E19.mkv"

	assert_success
	assert_json_equal "$output" '{
		"filename": "Psych_S0E19.mkv",
		"seriesId": null,
		"seriesName": "Psych",
		"formattedSeriesName": "Psych",
		"seriesSearchTerm": "psych",
		"seriesReleaseYear": null,
		"seasonNumber": 0,
		"formattedSeasonNum": "00",
		"episodeNumber": 19,
		"formattedEpisodeNum": "19",
		"extension": "mkv"
	}'

	run get-tv-info-from-filename "Psych_S00E19.mkv"

	assert_success
	assert_json_equal "$output" '{
		"filename": "Psych_S00E19.mkv",
		"seriesId": null,
		"seriesName": "Psych",
		"formattedSeriesName": "Psych",
		"seriesSearchTerm": "psych",
		"seriesReleaseYear": null,
		"seasonNumber": 0,
		"formattedSeasonNum": "00",
		"episodeNumber": 19,
		"formattedEpisodeNum": "19",
		"extension": "mkv"
	}'
}

@test "7 - get-tv-info-from-filename: season-identifier is lowercase" {
	run get-tv-info-from-filename "StarTrekTheNextGeneration_s02E18.mkv"

	assert_success
	assert_json_equal "$output" '{
		"filename": "StarTrekTheNextGeneration_s02E18.mkv",
		"seriesId": null,
		"seriesName": "StarTrekTheNextGeneration",
		"formattedSeriesName": "Star Trek The Next Generation",
		"seriesSearchTerm": "star trek the next generation",
		"seriesReleaseYear": null,
		"seasonNumber": 2,
		"formattedSeasonNum": "02",
		"episodeNumber": 18,
		"formattedEpisodeNum": "18",
		"extension": "mkv"
	}'
}

@test "8 - get-tv-info-from-filename: filename has single digit episode" {
	run get-tv-info-from-filename "Sherlock_S01E5.mkv"

	assert_success
	assert_output "$output" '{
		"filename":"Sherlock_S01E5.mkv",
		"seriesId":null,
		"seriesName":"Sherlock",
		"formattedSeriesName":"Sherlock",
		"seriesSearchTerm":"sherlock",
		"seriesReleaseYear": null,
		"seasonNumber":1,
		"formattedSeasonNum":"01",
		"episodeNumber":5,
		"formattedEpisodeNum":"05",
		"extension":"mkv"
		}'
}

@test "9 - get-tv-info-from-filename: filename has two digit episode" {
	run get-tv-info-from-filename "Sherlock_S01E05.mkv"

	assert_success
	assert_output "$output" '{
		"filename":"Sherlock_S01E05.mkv",
		"seriesId":null,
		"seriesName":"Sherlock",
		"formattedSeriesName":"Sherlock",
		"seriesSearchTerm":"sherlock",
		"seriesReleaseYear": null,
		"seasonNumber":1,
		"formattedSeasonNum":"01",
		"episodeNumber":5,
		"formattedEpisodeNum":"05",
		"extension":"mkv"
		}'

	run get-tv-info-from-filename "Sherlock_S01E17.mkv"

	assert_success
	assert_output "$output" '{
		"filename":"Sherlock_S01E17.mkv",
		"seriesId":null,
		"seriesName":"Sherlock",
		"formattedSeriesName":"Sherlock",
		"seriesSearchTerm":"sherlock",
		"seriesReleaseYear": null,
		"seasonNumber":1,
		"formattedSeasonNum":"01",
		"episodeNumber":17,
		"formattedEpisodeNum":"17",
		"extension":"mkv"
		}'
}

@test "10 - get-tv-info-from-filename: episode-identifier is lowercase" {
	run get-tv-info-from-filename "StarTrekTheNextGeneration_S02e18.mkv"

	assert_success
	assert_output "$output" '{
		"filename":"StarTrekTheNextGeneration_S02e18.mkv",
		"seriesId":null,
		"seriesName":"StarTrekTheNextGeneration",
		"formattedSeriesName":"Star Trek The Next Generation",
		"seriesSearchTerm":"star trek the next generation",
		"seriesReleaseYear": null,
		"seasonNumber":2,
		"formattedSeasonNum":"02",
		"episodeNumber":18,
		"formattedEpisodeNum":"18",
		"extension":"mkv"
		}'
}

@test "11 - get-tv-info-from-filename: series has multiple words" {
	run get-tv-info-from-filename "StarTrekTheNextGeneration_S02E18.mkv"

	assert_success
	assert_output "$output" '{
		"filename":"StarTrekTheNextGeneration_S02E18.mkv",
		"seriesId":null,
		"seriesName":"StarTrekTheNextGeneration",
		"formattedSeriesName":"Star Trek The Next Generation",
		"seriesSearchTerm":"star trek the next generation",
		"seriesReleaseYear": null,
		"seasonNumber":2,
		"formattedSeasonNum":"02",
		"episodeNumber":18,
		"formattedEpisodeNum":"18",
		"extension":"mkv"
		}'
}

@test "12 - get-tv-info-from-filename: series has words separated by spaces, periods, dashes or underscores" {
	run get-tv-info-from-filename "Star.Trek_The-Next   Generation_S02E18.mkv"

	assert_success
	assert_output "$output" '{
		"filename":"Star.Trek_The-Next   Generation_S02E18.mkv",
		"seriesId":null,
		"seriesName":"Star.Trek_The-Next   Generation",
		"formattedSeriesName":"Star Trek The Next Generation",
		"seriesSearchTerm":"star trek the next generation",
		"seriesReleaseYear": null,
		"seasonNumber":2,
		"formattedSeasonNum":"02",
		"episodeNumber":18,
		"formattedEpisodeNum":"18",
		"extension":"mkv"
		}'
}

@test "13 - get-tv-info-from-filename: period character between series name and season identifier" {
	run get-tv-info-from-filename "Sherlock Holmes.S03E04.mp4"

	assert_success
	assert_output "$output" '{
		"filename":"Sherlock Holmes.S03E04.mp4",
		"seriesId":null,
		"seriesName":"Sherlock Holmes",
		"formattedSeriesName":"Sherlock Holmes",
		"seriesSearchTerm":"sherlock holmes",
		"seriesReleaseYear": null,
		"seasonNumber":3,
		"formattedSeasonNum":"03",
		"episodeNumber":4,
		"formattedEpisodeNum":"04",
		"extension":"mp4"
		}'
}

@test "14 - get-tv-info-from-filename: space character between series name and season identifier" {
	run get-tv-info-from-filename "Sherlock Holmes S03E04.avi"

	assert_success
	assert_output "$output" '{
		"filename":"Sherlock Holmes S03E04.avi",
		"seriesId":null,
		"seriesName":"Sherlock Holmes",
		"formattedSeriesName":"Sherlock Holmes",
		"seriesSearchTerm":"sherlock holmes",
		"seriesReleaseYear": null,
		"seasonNumber":3,
		"formattedSeasonNum":"03",
		"episodeNumber":4,
		"formattedEpisodeNum":"04",
		"extension":"avi"
		}'
}

@test "15 - get-tv-info-from-filename: dash character between series name and season identifier" {
	run get-tv-info-from-filename "Sherlock Holmes-S03E04.m4v"

	assert_success
	assert_output "$output" '{
		"filename":"Sherlock Holmes-S03E04.m4v",
		"seriesId":null,
		"seriesName":"Sherlock Holmes",
		"formattedSeriesName":"Sherlock Holmes",
		"seriesSearchTerm":"sherlock holmes",
		"seriesReleaseYear": null,
		"seasonNumber":3,
		"formattedSeasonNum":"03",
		"episodeNumber":4,
		"formattedEpisodeNum":"04",
		"extension":"m4v"
		}'
}
