#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH
CACHE_DIRECTORY="/tmp/usr/tvdb-cache"
TMP_STORAGE_DIRECTORY="/tmp/usr/tmp_store"

setup() {
	PATH="$PATH:$UTILITIES_SRC_DIR"
	mkdir -p "$TMP_STORAGE_DIRECTORY"

	mkdir -p "$CACHE_DIRECTORY"
	if [[ -n $(ls -A "$CACHE_DIRECTORY") ]]; then
		pushd "$CACHE_DIRECTORY" > /dev/null
		mv .??* "$TMP_STORAGE_DIRECTORY"
		popd > /dev/null
	fi
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"

	pushd "$CACHE_DIRECTORY" > /dev/null
	rm .??*
	popd > /dev/null

	if [[ -n $(ls -A "$TMP_STORAGE_DIRECTORY") ]]; then
		pushd "$TMP_STORAGE_DIRECTORY" > /dev/null
		mv .??* "$CACHE_DIRECTORY/"
		popd > /dev/null
	fi
	rmdir "$TMP_STORAGE_DIRECTORY"
}

@test "1 - tvdb-get-series-episode-details UNIT : where no series id provided should error" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details
	assert_failure
	assert_output "ERROR: No series id provided."
}

@test "2 - tvdb-get-series-episode-details INT : where ignoring cache and series found and season number and episode number provided but episode doesnt exist and should return null" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 1 78 --ignore-cache
	assert_success
	assert_output "null"
}

@test "3 - tvdb-get-series-episode-details INT : where using cache and series found in cache and season number and episode number provided but episode doesnt exist and doesnt exist online should return null" {
	fakeCacheFile="$CACHE_DIRECTORY/.219631"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"The Mammy\"},{\"season\":1,\"episode\":2,\"name\":\"Mammy's Secret\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 219631 1 78 --use-cache
	assert_success
	assert_output "null"
}

@test "4 - tvdb-get-series-episode-details INT : where using cache and series found in cache and season number and episode number provided but episode doesnt exist in cache but does exist online should return episode details" {
	fakeCacheFile="$CACHE_DIRECTORY/.219631"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"The Mammy\"},{\"season\":1,\"episode\":2,\"name\":\"Mammy's Secret\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 219631 1 4 --use-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":4,\"name\":\"Mammy Rides Again\"}]"
}

@test "5 - tvdb-get-series-episode-details INT : where using cache and series found and season number and episode number provided should return episode details from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.71470"
	echo "[{\"season\":3,\"episode\":7,\"name\":\"A Cached copy of the name\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 3 7 --use-cache
	assert_success
	assert_output "[{\"season\":3,\"episode\":7,\"name\":\"A Cached copy of the name\"}]"
}

@test "6 - tvdb-get-series-episode-details INT : where ignoring cache and series found and season number and episode number provided should return episode details from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.71470"
	echo "[{\"season\":3,\"episode\":7,\"name\":\"A Cached copy of the name\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 3 7 --ignore-cache
	assert_success
	assert_output "[{\"season\":3,\"episode\":7,\"name\":\"The Enemy\"}]"
}

@test "7 - tvdb-get-series-episode-details INT : where using cache and series found and season number provided should return episode details for all episodes in season from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.176941"
	echo "[{\"season\":2,\"episode\":1,\"name\":\"Episode-2-1\"},{\"season\":2,\"episode\":2,\"name\":\"Episode-2-2\"},{\"season\":3,\"episode\":1,\"name\":\"Episode-3-1\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 176941 2 --use-cache
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"Episode-2-1\"},{\"season\":2,\"episode\":2,\"name\":\"Episode-2-2\"}]"
}

@test "8 - tvdb-get-series-episode-details INT : where ignoring cache and series found and season number provided should return episode details for all episodes in season from API" {
	fakeCacheFile="$CACHE_DIRECTORY/.176941"
	echo "[{\"season\":2,\"episode\":1,\"name\":\"Episode-2-1\"},{\"season\":2,\"episode\":2,\"name\":\"Episode-2-2\"},{\"season\":3,\"episode\":1,\"name\":\"Episode-3-1\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 176941 2 --ignore-cache
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"A Scandal in Belgravia\"},{\"season\":2,\"episode\":2,\"name\":\"The Hounds of Baskerville\"},{\"season\":2,\"episode\":3,\"name\":\"The Reichenbach Fall\"}]"
}

@test "9 - tvdb-get-series-episode-details INT : where using cache and series found and no season or episode number provided should return episode details for all episodes in all seasons from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"episode-1-1\"},{\"season\":1,\"episode\":2,\"name\":\"episode-1-2\"},{\"season\":2,\"episode\":1,\"name\":\"episode-2-1\"},{\"season\":2,\"episode\":2,\"name\":\"episode-2-2\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 --use-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":1,\"name\":\"episode-1-1\"},{\"season\":1,\"episode\":2,\"name\":\"episode-1-2\"},{\"season\":2,\"episode\":1,\"name\":\"episode-2-1\"},{\"season\":2,\"episode\":2,\"name\":\"episode-2-2\"}]"
}

@test "10 - tvdb-get-series-episode-details INT : where ignoring cache and series found and no season or episode number provided should return episode details for all episodes in all seasons from API" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"episode-1-1\"},{\"season\":1,\"episode\":2,\"name\":\"episode-1-2\"},{\"season\":2,\"episode\":1,\"name\":\"episode-2-1\"},{\"season\":2,\"episode\":2,\"name\":\"episode-2-2\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 --ignore-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\"}]"
}

@test "11 - tvdb-get-series-episode-details INT : use-cache is the default" {
	fakeCacheFile="$CACHE_DIRECTORY/.71470"
	echo "[{\"season\":2,\"episode\":1,\"name\":\"A Cached copy of the name\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 2 1
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"A Cached copy of the name\"}]"
}

@test "12 - tvdb-get-series-episode-details INT : where using cache and no cached file exists should return episode details from API" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3  --use-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"}]"

	assert [ ! -e "$CACHE_DIRECTORY/.78874" ]
}

@test "13 - tvdb-get-series-episode-details INT : where ignoring cache and cached file exists should return episode details from API" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":3,\"name\":\"Stupid McStupid Head\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3 --ignore-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"}]"

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileContents=$(cat "$CACHE_DIRECTORY/.78874")
	assert [ "$cachedFileContents" == "[{\"season\":1,\"episode\":3,\"name\":\"Stupid McStupid Head\"}]" ]
}

@test "14 - tvdb-get-series-episode-details INT : where using cache and saving to cache and no cached file exists should return episode details from API and save series details in cache" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3 --use-cache --update-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"}]"

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileDetails=$(cat "$CACHE_DIRECTORY/.78874")
	assert [ "$cachedFileDetails" == "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\"}]" ]
}

@test "15 - tvdb-get-series-episode-details INT : where ignoring cache and cached file exists and saving to cache should return episode details from API and save series details in cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":3,\"name\":\"Stupid McStupid Head\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3 --ignore-cache --update-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"}]"

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileDetails=$(cat "$CACHE_DIRECTORY/.78874")
	assert [ "$cachedFileDetails" == "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\"}]" ]
}
