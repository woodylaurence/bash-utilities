#!/bin/bash

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

@test "1 - get-date-as-number UNIT : where no date format provided" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number
	assert_failure
	assert_output "ERROR: date format not supplied"
}

@test "2 - get-date-as-number UNIT : where date format not valid" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "mj akjhsda klsdf" "2016-01-05"
	assert_failure
	assert_output "ERROR: date format not valid"

	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "2016-01-05" "2016-01-01"
	assert_failure
	assert_output "ERROR: date format not valid"
}

@test "3 - get-date-as-number UNIT : where no date provided" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-mm-yy"
	assert_failure
	assert_output "ERROR: date not supplied"
}

@test "4 - get-date-as-number INT : allows separators of ' ', '/' and '-'" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "yyyy-mm-dd" "2001 06 21"
	assert_success
	assert_output "20010621"

	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "yyyy-mm-dd" "2001/06/21"
	assert_success
	assert_output "20010621"

	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "yyyy-mm-dd" "2001-06-21"
	assert_success
	assert_output "20010621"

	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "yyyy-mm-dd" "2001 06-21"
	assert_success
	assert_output "20010621"
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "yyyy-mm-dd" "2001/06-21"
	assert_success
	assert_output "20010621"
}

@test "5 - get-date-as-number INT : where format is yyyy mm dd" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "yyyy-mm-dd" "2018-05-19"
	assert_success
	assert_output "20180519"
}

@test "6 - get-date-as-number INT : where format is dd mm yy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-mm-yy" "15 08 16"
	assert_success
	assert_output "20160815"
}

@test "7 - get-date-as-number INT : where format is dd mm yyyy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-mm-yyyy" "23 01 2009"
	assert_success
	assert_output "20090123"
}

@test "8 - get-date-as-number INT : where format is mm dd yy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "mm-dd-yy" "12 13 16"
	assert_success
	assert_output "20161213"
}

@test "9 - get-date-as-number INT : where format is dd MM yy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-MM-yy" "24 Feb 18"
	assert_success
	assert_output "20180224"
}

@test "10 - get-date-as-number INT : where format is dd MM yyyy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-MM-yyyy" "13 Jan 1999"
	assert_success
	assert_output "19990113"
}

@test "11 - get-date-as-number INT : where format is dd MMM yy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-MMM-yy" "14 December 15"
	assert_success
	assert_output "20151214"
}

@test "12 - get-date-as-number INT : where format is dd MMM yyyy" {
	run "$UTILITIES_SRC_DIR"/get-date-as-number -f "dd-MMM-yyyy" "01 January 2009"
	assert_success
	assert_output "20090101"
}
