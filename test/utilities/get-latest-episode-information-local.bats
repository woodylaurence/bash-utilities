#!/bin/bash

load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH
TEMP_MEDIA_DIRECTORY="./temp-directory"

setup() {
	PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")

	mkdir -p "$TEMP_MEDIA_DIRECTORY"
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"

	rm -rf "$TEMP_MEDIA_DIRECTORY"
}

@test "1 - get-latest-episode-information-local UNIT : not supplying directory to search should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-local
	assert_failure
	assert_output "ERROR: no directory to search provided"
}

@test "2 - get-latest-episode-information-local UNIT : supplied directory does not exist should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-local "wrong-directory"
	assert_failure
	assert_output "ERROR: supplied directory does not exist"
}

@test "3 - get-latest-episode-information-local UNIT : not supplying series name to search should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-local "./"
	assert_failure
	assert_output "ERROR: no series name provided"
}

@test "4 - get-latest-episode-information-local INT : where series does not exist should return " {
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 2"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 3"

	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1/01 File1.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1/02 File2.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 2/04 File3.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 3/01 File4.mp4"

	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-local "$TEMP_MEDIA_DIRECTORY" "West Wing"
	assert_success
	assert_output "{\"series\":\"West Wing\",\"latestSeason\":0,\"latestEpisode\":0}"
}

@test "5 - get-latest-episode-information-local INT : latest episode is less than 10 should output number without preceeding 0" {
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 2"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 3"

	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1/01 File1.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1/02 File2.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 2/04 File3.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 3/01 File4.mp4"

	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing"
	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing/Season 1"
	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing/Season 2"
	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing/Season 3"

	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 1/01 File1.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 1/02 File2.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 2/04 File3.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 3/01 File4.mp4"

	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-local "$TEMP_MEDIA_DIRECTORY" "West Wing"
	assert_success
	assert_output "{\"series\":\"West Wing\",\"latestSeason\":3,\"latestEpisode\":1}"
}

@test "6 - get-latest-episode-information-local INT : latest episode is greater than 10 should output number" {
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 2"
	mkdir "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 3"

	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1/01 File1.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 1/02 File2.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 2/04 File3.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/Not Our Series/Season 3/01 File4.mp4"

	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing"
	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing/Season 1"
	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing/Season 2"
	mkdir "$TEMP_MEDIA_DIRECTORY/West Wing/Season 3"

	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 1/01 File1.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 1/02 File2.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 2/04 File3.mp4"
	touch "$TEMP_MEDIA_DIRECTORY/West Wing/Season 3/21 File4.mp4"

	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-local "$TEMP_MEDIA_DIRECTORY" "West Wing"
	assert_success
	assert_output "{\"series\":\"West Wing\",\"latestSeason\":3,\"latestEpisode\":21}"
}
