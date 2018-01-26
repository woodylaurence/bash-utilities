#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities";
CACHED_TOKEN_FILE="/tmp/usr/tvdb-cache/.tvdb-token-cache"

setup() {
	if [[ -z "$TVDB_API_KEY" ]]; then
		echo "TVDB_API_KEY not found in environment variables..."
		assert_failure
	fi

	if [[ -e "$CACHED_TOKEN_FILE" ]]; then
		mv "$CACHED_TOKEN_FILE" "${CACHED_TOKEN_FILE}.moved"
	fi
}

teardown() {
	if [[ -e "${CACHED_TOKEN_FILE}.moved" ]]; then
		mv "${CACHED_TOKEN_FILE}.moved" "$CACHED_TOKEN_FILE"
	fi
}

@test "1 - tvdb-authenticate INT : no api-key provided" {
	run "$UTILITIES_SRC_DIR"/tvdb-authenticate
	assert_failure
	assert_output "ERROR: no API key provided."
}

@test "2 - tvdb-authenticate INT : providing invalid key should return no token" {
	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "wrong-key"
	assert_success
	assert_output "null"
}

@test "3 - tvdb-authenticate INT : no cached token, providing valid key should return valid token" {
	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "$TVDB_API_KEY"
	assert_success
	assert_output --regexp "^[A-Za-z0-9_.-]{464}$"
}

@test "4 - tvdb-authenticate INT : cached token exists, providing valid key should return token from cache" {
	cachedTokenValue="fake-token-value"
	echo "$cachedTokenValue" > "$CACHED_TOKEN_FILE"

	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "$TVDB_API_KEY"
	assert_success
	assert_output "$cachedTokenValue"
}

@test "5 - tvdb-authenticate INT : cached token exists and edited less than 24 hours ago should return token from cache" {
	cachedTokenValue="fake-token-value"
	echo "$cachedTokenValue" > "$CACHED_TOKEN_FILE"
	touch -d "23 hours ago" "$CACHED_TOKEN_FILE"

	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "$TVDB_API_KEY"
	assert_success
	assert_output "$cachedTokenValue"
}

@test "6 - tvdb-authenticate INT : cached token exists and edited 24 hours ago should return token from cache" {
	cachedTokenValue="fake-token-value"
	echo "$cachedTokenValue" > "$CACHED_TOKEN_FILE"
	touch -d "24 hours ago" "$CACHED_TOKEN_FILE"

	run "$UTILITIES_SRC_DIR"/tvdb-authenticate "$TVDB_API_KEY"
	assert_success
	assert_output --regexp "^[A-Za-z0-9_.-]{464}$"
}
