#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

CACHED_TOKEN_FILE="/tmp/usr/tvdb-cache/.tvdb-token-cache"

setup() {
	if [[ -z "$TVDB_API_KEY" ]]; then
		echo "TVDB_API_KEY not found in environment variables..." >&2
		return 1
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

@test "1 - tvdb-authenticate : no api-key provided" {
	run tvdb-authenticate

	assert_failure
	assert_output --partial "ERROR - No API token provided."
}

@test "2 - tvdb-authenticate : providing invalid key should return no token" {
	run tvdb-authenticate "wrong-key"

	assert_failure
	assert_output --partial "ERROR - failure trying to authenticate. Message = '"
}

@test "3 - tvdb-authenticate : no cached token, providing valid key should return valid token" {
	run tvdb-authenticate "$TVDB_API_KEY"

	assert_success
	assert_output --regexp "^[A-Za-z0-9_.-]{300,}$"
}

@test "4 - tvdb-authenticate : cached token exists and edited less than 24 hours ago should return token from cache" {
	cached_token_value="fake-token-value"
	echo "$cached_token_value" > "$CACHED_TOKEN_FILE"
	touch -d "23 hours ago" "$CACHED_TOKEN_FILE"

	run tvdb-authenticate "$TVDB_API_KEY"

	assert_success
	assert_output "$cached_token_value"
}

@test "5 - tvdb-authenticate : cached token exists and edited 24 hours ago should not return token from cache" {
	cached_token_value="fake-token-value"
	echo "$cached_token_value" > "$CACHED_TOKEN_FILE"
	touch -d "24 hours ago" "$CACHED_TOKEN_FILE"

	run tvdb-authenticate "$TVDB_API_KEY"

	assert_success
	refute_output "$cached_token_value"
	assert_output --regexp "^[A-Za-z0-9_.-]{300,}$"
}
