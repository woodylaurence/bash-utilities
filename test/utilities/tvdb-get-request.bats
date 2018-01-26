#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities";

@test "1 - tvdb-get-request UNIT : no api-token provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-request
	assert_failure
	assert_output "ERROR: No API token provided."
}

@test "2 - tvdb-get-request UNIT : no request url provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-request "fake-api-token"
	assert_failure
	assert_output "ERROR: No API request URL provided."
}

@test "3 - tvdb-get-request INT" {
	token=$("$UTILITIES_SRC_DIR"/tvdb-authenticate $TVDB_API_KEY)

	run "$UTILITIES_SRC_DIR"/tvdb-get-request $token "/refresh_token"

	assert_output --regexp "^\{\s+\"token\":\s+\"[A-Za-z0-9_.-]{464}\"\s+\}$"
}
