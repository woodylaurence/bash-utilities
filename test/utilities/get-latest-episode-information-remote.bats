#!/bin/bash

#####These tests use the get-latest-episode-information-local residing in /usr/local/bin

load ../helpers/bats-support/load
load ../helpers/bats-assert/load

ORIGINAL_PATH_VARIABLE=$PATH

UTILITIES_SRC_DIR="../../src/utilities"
TEMP_MEDIA_DIRECTORY=$(readlink -f "./temp directory")

setup() {
	if [[ -z "$LOCAL_HOST" ]]; then
		assert_failure "LOCAL_HOST variable is not set."
	fi

	PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")
	mkdir -p "$TEMP_MEDIA_DIRECTORY"
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"

	rm -rf "$TEMP_MEDIA_DIRECTORY"
}

@test "1 - get-latest-episode-information-remote UNIT : where no remote server address provided should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-remote
	assert_failure
	assert_output "ERROR: no remote server address provided"
}

@test "2 - get-latest-episode-information-remote UNIT : where no directory provided should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-remote "$LOCAL_HOST"
	assert_failure
	assert_output "ERROR: no directory provided"
}

@test "3 - get-latest-episode-information-remote UNIT : where no series name provided should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-remote "$LOCAL_HOST" "$TEMP_MEDIA_DIRECTORY"
	assert_failure
	assert_output "ERROR: no series name provided"
}

@test "4 - get-latest-episode-information-remote UNIT : where directory does not exist on remote server should error" {
	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-remote "$LOCAL_HOST" "/some/directory/that/doesnt/exist" "Psych"
	assert_failure
	assert_output "ERROR: supplied directory does not exist"
}

@test "5 - get-latest-episode-information-remote INT" {
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

	run "$UTILITIES_SRC_DIR"/get-latest-episode-information-remote "$LOCAL_HOST" "$TEMP_MEDIA_DIRECTORY" "West Wing"
	assert_success
	assert_output "{\"series\":\"West Wing\",\"latestSeason\":3,\"latestEpisode\":1}"
}
