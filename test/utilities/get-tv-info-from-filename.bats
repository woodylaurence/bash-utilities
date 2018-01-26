#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH

setup() {
	PATH="$PATH:$UTILITIES_SRC_DIR"
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"
}

@test "1 - get-tv-info-from-filename INT : filename doesnt have series name" {
	fakeFilename="S01E01.mkv"

	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fakeFilename
	assert_failure
	assert_output "ERROR: Filename '$fakeFilename' cannot be parsed as tv episode"
}

@test "2 - get-tv-info-from-filename INT : filename has invalid or missing season number" {
	fileNameWithMissingSeasonIdentifier="StarTrek_E01.mkv"
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fileNameWithMissingSeasonNumber
	assert_failure
	assert_output "ERROR: Filename '$fileNameWithMissingSeasonNumber' cannot be parsed as tv episode"

	fileNameWithMissingSeasonNumber="StarTrek_SE01.mkv"
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fileNameWithMissingSeasonNumber
	assert_failure
	assert_output "ERROR: Filename '$fileNameWithMissingSeasonNumber' cannot be parsed as tv episode"

	fileNameWithNonNumericSeasonNumber="StarTrek_SfE01.mkv"
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fileNameWithNonNumericSeasonNumber
	assert_failure
	assert_output "ERROR: Filename '$fileNameWithNonNumericSeasonNumber' cannot be parsed as tv episode"
}

@test "3 - get-tv-info-from-filename INT : filename has invalid or missing episode number" {
	fileNameWithMissingEpisodeIdentifier="StarTrek_S01.mkv"
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fileNameWithMissingEpisodeIdentifier
	assert_failure
	assert_output "ERROR: Filename '$fileNameWithMissingEpisodeIdentifier' cannot be parsed as tv episode"

	fileNameWithMissingEpisodeNumber="StarTrek_S01E.mkv"
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fileNameWithMissingEpisodeNumber
	assert_failure
	assert_output "ERROR: Filename '$fileNameWithMissingEpisodeNumber' cannot be parsed as tv episode"

	fileNameWithNonNumericSeasonNumber="StarTrek_S01Ej.mkv"
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fileNameWithNonNumericSeasonNumber
	assert_failure
	assert_output "ERROR: Filename '$fileNameWithNonNumericSeasonNumber' cannot be parsed as tv episode"
}

@test "4 - get-tv-info-from-filename INT : filename has single digit season" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Psych_S1E19.mkv"
	assert_success
	assert_output "{
\"filename\":\"Psych_S1E19.mkv\",
\"seriesId\":null,
\"seriesName\":\"Psych\",
\"formattedSeriesName\":\"Psych\",
\"seriesSearchTerm\":\"psych\",
\"seasonNumber\":1,
\"formattedSeasonNum\":\"01\",
\"episodeNumber\":19,
\"formattedEpisodeNum\":\"19\",
\"extension\":\"mkv\"
}"
}

@test "get-tv-info-from-filename INT : filename has two digit season" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Psych_S01E19.mkv"
	assert_success
	assert_output "{
\"filename\":\"Psych_S01E19.mkv\",
\"seriesId\":null,
\"seriesName\":\"Psych\",
\"formattedSeriesName\":\"Psych\",
\"seriesSearchTerm\":\"psych\",
\"seasonNumber\":1,
\"formattedSeasonNum\":\"01\",
\"episodeNumber\":19,
\"formattedEpisodeNum\":\"19\",
\"extension\":\"mkv\"
}"

	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Psych_S14E19.mkv"
	assert_success
	assert_output "{
\"filename\":\"Psych_S14E19.mkv\",
\"seriesId\":null,
\"seriesName\":\"Psych\",
\"formattedSeriesName\":\"Psych\",
\"seriesSearchTerm\":\"psych\",
\"seasonNumber\":14,
\"formattedSeasonNum\":\"14\",
\"episodeNumber\":19,
\"formattedEpisodeNum\":\"19\",
\"extension\":\"mkv\"
}"
}

@test "5 - get-tv-info-from-filename INT : season-identifier is lowercase" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "StarTrekTheNextGeneration_s02E18.mkv"
	assert_success
	assert_output "{
\"filename\":\"StarTrekTheNextGeneration_s02E18.mkv\",
\"seriesId\":null,
\"seriesName\":\"StarTrekTheNextGeneration\",
\"formattedSeriesName\":\"Star Trek The Next Generation\",
\"seriesSearchTerm\":\"star trek the next generation\",
\"seasonNumber\":2,
\"formattedSeasonNum\":\"02\",
\"episodeNumber\":18,
\"formattedEpisodeNum\":\"18\",
\"extension\":\"mkv\"
}"
}

@test "6 - get-tv-info-from-filename INT : filename has single digit episode" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock_S01E5.mkv"
	assert_success
	assert_output "{
\"filename\":\"Sherlock_S01E5.mkv\",
\"seriesId\":null,
\"seriesName\":\"Sherlock\",
\"formattedSeriesName\":\"Sherlock\",
\"seriesSearchTerm\":\"sherlock\",
\"seasonNumber\":1,
\"formattedSeasonNum\":\"01\",
\"episodeNumber\":5,
\"formattedEpisodeNum\":\"05\",
\"extension\":\"mkv\"
}"
}

@test "7 - get-tv-info-from-filename INT : filename has two digit episode" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock_S01E05.mkv"
	assert_success
	assert_output "{
\"filename\":\"Sherlock_S01E05.mkv\",
\"seriesId\":null,
\"seriesName\":\"Sherlock\",
\"formattedSeriesName\":\"Sherlock\",
\"seriesSearchTerm\":\"sherlock\",
\"seasonNumber\":1,
\"formattedSeasonNum\":\"01\",
\"episodeNumber\":5,
\"formattedEpisodeNum\":\"05\",
\"extension\":\"mkv\"
}"

	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock_S01E17.mkv"
	assert_success
	assert_output "{
\"filename\":\"Sherlock_S01E17.mkv\",
\"seriesId\":null,
\"seriesName\":\"Sherlock\",
\"formattedSeriesName\":\"Sherlock\",
\"seriesSearchTerm\":\"sherlock\",
\"seasonNumber\":1,
\"formattedSeasonNum\":\"01\",
\"episodeNumber\":17,
\"formattedEpisodeNum\":\"17\",
\"extension\":\"mkv\"
}"
}

@test "8 - get-tv-info-from-filename INT : episode-identifier is lowercase" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "StarTrekTheNextGeneration_S02e18.mkv"
	assert_success
	assert_output "{
\"filename\":\"StarTrekTheNextGeneration_S02e18.mkv\",
\"seriesId\":null,
\"seriesName\":\"StarTrekTheNextGeneration\",
\"formattedSeriesName\":\"Star Trek The Next Generation\",
\"seriesSearchTerm\":\"star trek the next generation\",
\"seasonNumber\":2,
\"formattedSeasonNum\":\"02\",
\"episodeNumber\":18,
\"formattedEpisodeNum\":\"18\",
\"extension\":\"mkv\"
}"
}

@test "9 - get-tv-info-from-filename INT : series has multiple words" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "StarTrekTheNextGeneration_S02E18.mkv"
	assert_success
	assert_output "{
\"filename\":\"StarTrekTheNextGeneration_S02E18.mkv\",
\"seriesId\":null,
\"seriesName\":\"StarTrekTheNextGeneration\",
\"formattedSeriesName\":\"Star Trek The Next Generation\",
\"seriesSearchTerm\":\"star trek the next generation\",
\"seasonNumber\":2,
\"formattedSeasonNum\":\"02\",
\"episodeNumber\":18,
\"formattedEpisodeNum\":\"18\",
\"extension\":\"mkv\"
}"
}

@test "10 - get-tv-info-from-filename INT : series has words separated by spaces, periods, dashes or underscores" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Star.Trek_The-Next   Generation_S02E18.mkv"
	assert_success
	assert_output "{
\"filename\":\"Star.Trek_The-Next   Generation_S02E18.mkv\",
\"seriesId\":null,
\"seriesName\":\"Star.Trek_The-Next   Generation\",
\"formattedSeriesName\":\"Star Trek The Next Generation\",
\"seriesSearchTerm\":\"star trek the next generation\",
\"seasonNumber\":2,
\"formattedSeasonNum\":\"02\",
\"episodeNumber\":18,
\"formattedEpisodeNum\":\"18\",
\"extension\":\"mkv\"
}"
}

@test "11 - get-tv-info-from-filename INT : period character between series name and season identifier" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock Holmes.S03E04.mp4"
	assert_success
	assert_output "{
\"filename\":\"Sherlock Holmes.S03E04.mp4\",
\"seriesId\":null,
\"seriesName\":\"Sherlock Holmes\",
\"formattedSeriesName\":\"Sherlock Holmes\",
\"seriesSearchTerm\":\"sherlock holmes\",
\"seasonNumber\":3,
\"formattedSeasonNum\":\"03\",
\"episodeNumber\":4,
\"formattedEpisodeNum\":\"04\",
\"extension\":\"mp4\"
}"
}

@test "12 - get-tv-info-from-filename INT : space character between series name and season identifier" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock Holmes S03E04.avi"
	assert_success
	assert_output "{
\"filename\":\"Sherlock Holmes S03E04.avi\",
\"seriesId\":null,
\"seriesName\":\"Sherlock Holmes\",
\"formattedSeriesName\":\"Sherlock Holmes\",
\"seriesSearchTerm\":\"sherlock holmes\",
\"seasonNumber\":3,
\"formattedSeasonNum\":\"03\",
\"episodeNumber\":4,
\"formattedEpisodeNum\":\"04\",
\"extension\":\"avi\"
}"
}

@test "13 - get-tv-info-from-filename INT : dash character between series name and season identifier" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock Holmes-S03E04.m4v"
	assert_success
	assert_output "{
\"filename\":\"Sherlock Holmes-S03E04.m4v\",
\"seriesId\":null,
\"seriesName\":\"Sherlock Holmes\",
\"formattedSeriesName\":\"Sherlock Holmes\",
\"seriesSearchTerm\":\"sherlock holmes\",
\"seasonNumber\":3,
\"formattedSeasonNum\":\"03\",
\"episodeNumber\":4,
\"formattedEpisodeNum\":\"04\",
\"extension\":\"m4v\"
}"
}
