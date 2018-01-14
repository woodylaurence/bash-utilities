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

@test "tvdb-search-series UNIT : no search term provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series
	assert_failure
	assert_output "ERROR: No series search term provided."
}

@test "tvdb-search-series INT : no series found should return null" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series "fake-series"
	assert_success
	assert_output "null"
}

@test "tvdb-search-series INT : where exact match with single series found should return json with series name and id" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series "Star Trek: The Next Generation"

	assert_success
	assert_output "[{\"SeriesName\":\"Star Trek: The Next Generation\",\"SeriesId\":71470}]"
}

@test "tvdb-search-series INT : where match found with single series found should return json with series name and id" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series "Star Trek The Next Generation"

	assert_success
	assert_output "[{\"SeriesName\":\"Star Trek: The Next Generation\",\"SeriesId\":71470}]"
}

@test "tvdb-search-series INT : where match found via alias should return json with series name and id" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series "Star Trek Deep Space Nine"

	assert_success
	assert_output "[{\"SeriesName\":\"Star Trek: Deep Space Nine\",\"SeriesId\":72073}]"
}

@test "tvdb-search-series INT : where multiple matches found should return json with list of series name and id" {
	run "$UTILITIES_SRC_DIR"/tvdb-search-series "Psych"

	assert_success
	assert_output "[{\"SeriesName\":\"Psych\",\"SeriesId\":79335},{\"SeriesName\":\"Outrageous Acts of Psych\",\"SeriesId\":295027},{\"SeriesName\":\"SciShow Psych\",\"SeriesId\":340242},{\"SeriesName\":\"Big Brother's Bit On The Side\",\"SeriesId\":250481}]"
}
