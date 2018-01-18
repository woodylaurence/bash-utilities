#!/bin/bash

load helpers/mocks/stub
load helpers/bats-support/load
load helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH

setup() {
	PATH="$PATH:$UTILITIES_SRC_DIR"
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"
}

@test "get-tv-info-from-filename INT : filename doesnt have series name" {
	fakeFilename="S01E01.mkv"

	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename $fakeFilename
	assert_failure
	assert_output "ERROR: Filename '$fakeFilename' cannot be parsed as tv episode"
}

@test "get-tv-info-from-filename INT : filename has invalid or missing season number" {
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

@test "get-tv-info-from-filename INT : filename has invalid or missing episode number" {
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

@test "get-tv-info-from-filename INT : filename has single digit season" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Psych_S1E19.mkv"
	assert_success
	assert_output "{\"filename\":\"Psych_S1E19.mkv\",\"seriesName\":\"Psych\",\"formattedSeriesName\":\"Psych\",\"seasonNumber\":1,\"episodeNumber\":19}"
}

@test "get-tv-info-from-filename INT : filename has two digit season" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Psych_S01E19.mkv"
	assert_success
	assert_output "{\"filename\":\"Psych_S01E19.mkv\",\"seriesName\":\"Psych\",\"formattedSeriesName\":\"Psych\",\"seasonNumber\":1,\"episodeNumber\":19}"

	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Psych_S14E19.mkv"
	assert_success
	assert_output "{\"filename\":\"Psych_S14E19.mkv\",\"seriesName\":\"Psych\",\"formattedSeriesName\":\"Psych\",\"seasonNumber\":14,\"episodeNumber\":19}"
}

@test "get-tv-info-from-filename INT : season-identifier is lowercase" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "StarTrekTheNextGeneration_s02E18.mkv"
	assert_success
	assert_output "{\"filename\":\"StarTrekTheNextGeneration_s02E18.mkv\",\"seriesName\":\"StarTrekTheNextGeneration\",\"formattedSeriesName\":\"Star Trek The Next Generation\",\"seasonNumber\":2,\"episodeNumber\":18}"
}

@test "get-tv-info-from-filename INT : filename has single digit episode" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock_S01E5.mkv"
	assert_success
	assert_output "{\"filename\":\"Sherlock_S01E5.mkv\",\"seriesName\":\"Sherlock\",\"formattedSeriesName\":\"Sherlock\",\"seasonNumber\":1,\"episodeNumber\":5}"
}

@test "get-tv-info-from-filename INT : filename has two digit episode" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock_S01E05.mkv"
	assert_success
	assert_output "{\"filename\":\"Sherlock_S01E05.mkv\",\"seriesName\":\"Sherlock\",\"formattedSeriesName\":\"Sherlock\",\"seasonNumber\":1,\"episodeNumber\":5}"

	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock_S01E17.mkv"
	assert_success
	assert_output "{\"filename\":\"Sherlock_S01E17.mkv\",\"seriesName\":\"Sherlock\",\"formattedSeriesName\":\"Sherlock\",\"seasonNumber\":1,\"episodeNumber\":17}"
}

@test "get-tv-info-from-filename INT : episode-identifier is lowercase" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "StarTrekTheNextGeneration_S02e18.mkv"
	assert_success
	assert_output "{\"filename\":\"StarTrekTheNextGeneration_S02e18.mkv\",\"seriesName\":\"StarTrekTheNextGeneration\",\"formattedSeriesName\":\"Star Trek The Next Generation\",\"seasonNumber\":2,\"episodeNumber\":18}"
}

@test "get-tv-info-from-filename INT : series has multiple words" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "StarTrekTheNextGeneration_S02E18.mkv"
	assert_success
	assert_output "{\"filename\":\"StarTrekTheNextGeneration_S02E18.mkv\",\"seriesName\":\"StarTrekTheNextGeneration\",\"formattedSeriesName\":\"Star Trek The Next Generation\",\"seasonNumber\":2,\"episodeNumber\":18}"
}

@test "get-tv-info-from-filename INT : series has words separated by spaces, periods, dashes or underscores" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Star.Trek_The-Next   Generation_S02E18.mkv"
	assert_success
	assert_output "{\"filename\":\"Star.Trek_The-Next   Generation_S02E18.mkv\",\"seriesName\":\"Star.Trek_The-Next   Generation\",\"formattedSeriesName\":\"Star Trek The Next Generation\",\"seasonNumber\":2,\"episodeNumber\":18}"
}

@test "get-tv-info-from-filename INT : period character between series name and season identifier" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock Holmes.S03E04.mkv"
	assert_success
	assert_output "{\"filename\":\"Sherlock Holmes.S03E04.mkv\",\"seriesName\":\"Sherlock Holmes\",\"formattedSeriesName\":\"Sherlock Holmes\",\"seasonNumber\":3,\"episodeNumber\":4}"
}

@test "get-tv-info-from-filename INT : space character between series name and season identifier" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock Holmes S03E04.mkv"
	assert_success
	assert_output "{\"filename\":\"Sherlock Holmes S03E04.mkv\",\"seriesName\":\"Sherlock Holmes\",\"formattedSeriesName\":\"Sherlock Holmes\",\"seasonNumber\":3,\"episodeNumber\":4}"
}

@test "get-tv-info-from-filename INT : dash character between series name and season identifier" {
	run "$UTILITIES_SRC_DIR"/get-tv-info-from-filename "Sherlock Holmes-S03E04.mkv"
	assert_success
	assert_output "{\"filename\":\"Sherlock Holmes-S03E04.mkv\",\"seriesName\":\"Sherlock Holmes\",\"formattedSeriesName\":\"Sherlock Holmes\",\"seasonNumber\":3,\"episodeNumber\":4}"
}
