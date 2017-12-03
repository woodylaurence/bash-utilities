#!/bin/bash

load helpers/mocks/stub
load helpers/bats-support/load
load helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities";

@test "getDateWithMonthAsNumber UNIT : short month format" {
	shortMonth="Jun"
	expectedMonthAsNumber="49"

	stub getMonthAsNumber \
		 "$shortMonth : echo $expectedMonthAsNumber"

	actual=$("$UTILITIES_SRC_DIR"/getDateWithMonthAsNumber "12/$shortMonth/17")
	assert_equal "$actual" "12${expectedMonthAsNumber}17"

	unstub getMonthAsNumber
}

@test "getDateWithMonthAsNumber UNIT : long month format" {
	longMonth="February"
	expectedMonthAsNumber="876"

	stub getMonthAsNumber \
		 "$longMonth : echo $expectedMonthAsNumber"

	actual=$("$UTILITIES_SRC_DIR"/getDateWithMonthAsNumber "08/$longMonth/19")
	assert_equal "$actual" "08${expectedMonthAsNumber}19"

	unstub getMonthAsNumber
}

@test "getDateWithMonthAsNumber INT : short month format" {
	actual=$("$UTILITIES_SRC_DIR"/getDateWithMonthAsNumber "22/Apr/90")
	assert_equal "$actual" "220490"
}

@test "getDateWithMonthAsNumber INT : long month format" {
	actual=$("$UTILITIES_SRC_DIR"/getDateWithMonthAsNumber "18/July/78")
	assert_equal "$actual" "180778"
}
