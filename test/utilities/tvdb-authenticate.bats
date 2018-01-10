#!/bin/bash

load helpers/mocks/stub
load helpers/bats-support/load
load helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities";

setup() {
	if [[ -z "$TVDB_API_KEY" ]]; then
		echo "TVDB_API_KEY not found in environment variables..."
		assert_failure
	fi
}

@test "tvdb-authenticate INT : no api-key provided" {
	run "$UTILITIES_SRC_DIR"/tvdb-authenticate
	assert_failure
	assert_output "ERROR: no API key provided."
}

@test "tvdb-authenticate INT : providing invalid key should return no token" {
	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "wrong-key"
	assert_success
	assert_output "null"
}

@test "tvdb-authenticate INT : providing valid key should return valid token" {
	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "$TVDB_API_KEY"
	assert_success
	assert_output --regexp "^[A-Za-z0-9_.-]{464}$"
}
