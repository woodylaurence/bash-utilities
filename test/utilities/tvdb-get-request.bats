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

@test "1 - tvdb-get-request : no api-token provided should error" {
	run tvdb-get-request

	assert_failure
	assert_output --partial "ERROR - No API token provided."
}

@test "2 - tvdb-get-request : no request url provided should error" {
	run tvdb-get-request "fake-api-token"

	assert_failure
	assert_output --partial "ERROR - No API request URL provided."
}

@test "3 - tvdb-get-request" {
	token=$(tvdb-authenticate $TVDB_API_KEY)

	run tvdb-get-request $token "/genders"

	assert_success
	run jq -e '.status == "success"' <<< "$output"
	assert_success
}
