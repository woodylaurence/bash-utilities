#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH

setup() {
	PATH=PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"
}

@test "1 - tvdb-search-series-episode-details UNIT : where no series search term provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series-episode-details
	assert_failure
	assert_output "ERROR: No series search term provided."
}

@test "2 - tvdb-search-series-episode-details INT : where series found and season number and episode number provided but episode doesnt exist should return null" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series-episode-details "Star Trek The Next Generation" 1 78
	assert_success
	assert_output "null"
}

@test "3 - tvdb-search-series-episode-details INT : where series found and season number and episode number provided should return episode details" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series-episode-details "Star Trek The Next Generation" 3 7
	assert_success
	assert_output "[{\"season\":3,\"episode\":7,\"name\":\"The Enemy\"}]"
}

@test "4 - tvdb-search-series-episode-details INT : where series found and season number provided should return episode details for all episodes in season" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series-episode-details "Sherlock on Masterpiece" 2
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"A Scandal in Belgravia\"},{\"season\":2,\"episode\":2,\"name\":\"The Hounds of Baskerville\"},{\"season\":2,\"episode\":3,\"name\":\"The Reichenbach Fall\"}]"
}

@test "5 - tvdb-search-series-episode-details INT : where series found and no season or episode number provided should return episode details for all episodes in all seasons" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series-episode-details "Firefly"
	assert_success
	assert_output "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\"}]"
}

@test "6 - tvdb-search-series-episode-details INT : where multiple series found for search term should request input from user as to which series was requested" {
	assert_failure "Figure out how to pass string to script"
}
