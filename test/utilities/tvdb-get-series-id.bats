#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH
CACHED_SERIES_NAME_TO_ID_FILE="/tmp/usr/tvdb-cache/.series-name-id-cache"

setup() {
	PATH=PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")

	if [[ -e "$CACHED_SERIES_NAME_TO_ID_FILE" ]]; then
		mv "$CACHED_SERIES_NAME_TO_ID_FILE" "${CACHED_SERIES_NAME_TO_ID_FILE}.moved"
	fi
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"

	if [[ -e "${CACHED_SERIES_NAME_TO_ID_FILE}.moved" ]]; then
		mv "${CACHED_SERIES_NAME_TO_ID_FILE}.moved" "$CACHED_SERIES_NAME_TO_ID_FILE"
	fi
}

@test "1 - tvdb-get-series-id UNIT : where no series search term provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id

	assert_failure
	assert_output "ERROR: No series search term provided."
}

@test "2 - tvdb-get-series-id INT : where series not found" {
	seriesSearchTerm="star wars deep space nine"
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id "$seriesSearchTerm"

	assert_success
	assert_output "null"
}

@test "3 - tvdb-get-series-id INT : where series found" {
	seriesSearchTerm="star trek the next generation"
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id "$seriesSearchTerm"

	assert_success
	assert_output "{\"seriesSearchTerm\":\"$seriesSearchTerm\",\"seriesId\":71470}"
}

@test "4 - tvdb-get-series-id INT : where multiple series found for search term and no cached response file exists should request input from user as to which series was requested" {
	assert_failure "Need to work out a way to get user input to work in tests"

	seriesSearchTerm="psych"
	"$UTILITIES_SRC_DIR"/tvdb-get-series-id "$seriesSearchTerm"

	assert_success
	assert_output "[
  {
    \"seriesName\": \"Psych\",
    \"seriesId\": 79335
  },
  {
    \"seriesName\": \"Outrageous Acts of Psych\",
    \"seriesId\": 295027
  },
  {
    \"seriesName\": \"SciShow Psych\",
    \"seriesId\": 340242
  },
  {
    \"seriesName\": \"Big Brother's Bit On The Side\",
    \"seriesId\": 250481
  }
]
Multiple series found...Please select seriesId from above"
}

@test "5 - tvdb-get-series-id INT : where multiple series found and cached response exists but not for our search term should return multiple results" {
	assert_failure "Need to work out a way to get user input to work in tests"
}

@test "6 - tvdb-get-series-id INT : where multiple series found and cached response exists for our search term should return cached result" {
	echo "[{\"seriesSearchTerm\":\"mrs browns boys\",\"seriesId\":71564},{\"seriesSearchTerm\":\"Sherlock\",\"seriesId\":3785}]" > "$CACHED_SERIES_NAME_TO_ID_FILE"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id "Sherlock"
	assert_success
	assert_output "{\"seriesSearchTerm\":\"Sherlock\",\"seriesId\":3785}"
}
