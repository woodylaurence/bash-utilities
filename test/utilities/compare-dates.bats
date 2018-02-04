#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"

ORIGINAL_PATH_VARIABLE=$PATH

setup() {
	PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"
}

@test "1 - compare-dates UNIT : don't have two dates to compare should error" {
	run "$UTILITIES_SRC_DIR"/compare-dates
	assert_failure
	assert_output "ERROR: need two dates to compare"

	run "$UTILITIES_SRC_DIR"/compare-dates "2006-01-05"
	assert_failure
	assert_output "ERROR: need two dates to compare"
}

@test "2 - compare-dates INT : first date is less than second date should return -1" {
	run "$UTILITIES_SRC_DIR"/compare-dates "2006-09-12" "2008-09-12"
	assert_success
	assert_output "-1"

	run "$UTILITIES_SRC_DIR"/compare-dates "2006-09-12" "2006-10-12"
	assert_success
	assert_output "-1"

	run "$UTILITIES_SRC_DIR"/compare-dates "2006-09-12" "2006-09-13"
	assert_success
	assert_output "-1"
}

@test "3 - compare-dates INT : first date is greater than second date should return 1" {
	run "$UTILITIES_SRC_DIR"/compare-dates "2010-02-18" "2009-02-18"
	assert_success
	assert_output "1"

	run "$UTILITIES_SRC_DIR"/compare-dates "2010-02-18" "2010-01-18"
	assert_success
	assert_output "1"

	run "$UTILITIES_SRC_DIR"/compare-dates "2010-02-18" "2010-02-17"
	assert_success
	assert_output "1"
}

@test "4 - compare-dates INT : first date is same as second date should return 0" {
	run "$UTILITIES_SRC_DIR"/compare-dates "2003-05-17" "2003-05-17"
	assert_success
	assert_output "0"
}
