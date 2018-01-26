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

@test "1 - tvdb-get-series-id UNIT : where no series search term provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id

	assert_failure
	assert_output "ERROR: No series search term provided."
}

@test "2 - tvdb-search-series INT : where series found" {
	seriesSearchTerm="star wars deep space nine"
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id "$seriesSearchTerm"

	assert_success
	assert_output "{\"seriesSearchTerm\":\"$seriesSearchTerm\",\"seriesId\":null}"
}

@test "3 - tvdb-search-series INT : where series found" {
	seriesSearchTerm="star trek the next generation"
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-id "$seriesSearchTerm"

	assert_success
	assert_output "{\"seriesSearchTerm\":\"$seriesSearchTerm\",\"seriesId\":71470}"
}

@test "4 - tvdb-search-series INT : where multiple series found for search term should request input from user as to which series was requested" {
	seriesSearchTerm="psych"
	"$UTILITIES_SRC_DIR"/tvdb-get-series-id "$seriesSearchTerm"

	assert_failure "Need to work out a way to get user input to work in tests"
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
