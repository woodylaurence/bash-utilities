#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities"
ORIGINAL_PATH_VARIABLE=$PATH
CACHE_DIRECTORY="/tmp/usr/tvdb-cache"
TMP_STORAGE_DIRECTORY="/tmp/usr/tmp_store"

setup() {
	PATH=PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")
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
	echo "[{\"season\":1,\"episode\":1,\"name\":\"The Mammy\",\"airDate\":\"2011-01-01\"},{\"season\":1,\"episode\":2,\"name\":\"Mammy's Secret\",\"airDate\":\"2011-01-08\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 219631 1 78 --use-cache
	assert_success
	assert_output "null"
}

@test "4 - tvdb-get-series-episode-details INT : where using cache and series found in cache and season number and episode number provided but episode doesnt exist in cache but does exist online should return episode details" {
	fakeCacheFile="$CACHE_DIRECTORY/.219631"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"The Mammy\",\"airDate\":\"2011-01-01\"},{\"season\":1,\"episode\":2,\"name\":\"Mammy's Secret\",\"airDate\":\"2011-01-08\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 219631 1 4 --use-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":4,\"name\":\"Mammy Rides Again\",\"airDate\":\"2011-01-22\"}]"
}

@test "5 - tvdb-get-series-episode-details INT : where using cache and series found and season number and episode number provided should return episode details from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.71470"
	echo "[{\"season\":3,\"episode\":7,\"name\":\"A Cached copy of the name\",\"airDate\":\"2009-01-07\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 3 7 --use-cache
	assert_success
	assert_output "[{\"season\":3,\"episode\":7,\"name\":\"A Cached copy of the name\",\"airDate\":\"2009-01-07\"}]"
}

@test "6 - tvdb-get-series-episode-details INT : where ignoring cache and series found and season number and episode number provided should return episode details from TVDB" {
	fakeCacheFile="$CACHE_DIRECTORY/.71470"
	echo "[{\"season\":3,\"episode\":7,\"name\":\"A Cached copy of the name\",\"airDate\":\"2009-01-07\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 3 7 --ignore-cache
	assert_success
	assert_output "[{\"season\":3,\"episode\":7,\"name\":\"The Enemy\",\"airDate\":\"1989-11-06\"}]"
}

@test "7 - tvdb-get-series-episode-details INT : where using cache and series found and season number provided should return episode details for all episodes in season from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.176941"
	echo "[{\"season\":2,\"episode\":1,\"name\":\"Episode-2-1\",\"airDate\":\"2009-01-07\"},{\"season\":2,\"episode\":2,\"name\":\"Episode-2-2\",\"airDate\":\"2010-01-07\"},{\"season\":3,\"episode\":1,\"name\":\"Episode-3-1\",\"airDate\":\"2011-01-07\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 176941 2 --use-cache
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"Episode-2-1\",\"airDate\":\"2009-01-07\"},{\"season\":2,\"episode\":2,\"name\":\"Episode-2-2\",\"airDate\":\"2010-01-07\"}]"
}

@test "8 - tvdb-get-series-episode-details INT : where ignoring cache and series found and season number provided should return episode details for all episodes in season from API" {
	fakeCacheFile="$CACHE_DIRECTORY/.176941"
	echo "[{\"season\":2,\"episode\":1,\"name\":\"Episode-2-1\",\"airDate\":\"2009-01-07\"},{\"season\":2,\"episode\":2,\"name\":\"Episode-2-2\",\"airDate\":\"2010-01-07\"},{\"season\":3,\"episode\":1,\"name\":\"Episode-3-1\",\"airDate\":\"2009-01-08\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 176941 2 --ignore-cache
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"A Scandal in Belgravia\",\"airDate\":\"2012-01-01\"},{\"season\":2,\"episode\":2,\"name\":\"The Hounds of Baskerville\",\"airDate\":\"2012-01-08\"},{\"season\":2,\"episode\":3,\"name\":\"The Reichenbach Fall\",\"airDate\":\"2012-01-15\"}]"
}

@test "9 - tvdb-get-series-episode-details INT : where using cache and series found and no season or episode number provided should return episode details for all episodes in all seasons from cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"episode-1-1\",\"airDate\":\"2009-01-07\"},{\"season\":1,\"episode\":2,\"name\":\"episode-1-2\",\"airDate\":\"2010-02-07\"},{\"season\":2,\"episode\":1,\"name\":\"episode-2-1\",\"airDate\":\"2010-09-10\"},{\"season\":2,\"episode\":2,\"name\":\"episode-2-2\",\"airDate\":\"2012-01-03\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 --use-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":1,\"name\":\"episode-1-1\",\"airDate\":\"2009-01-07\"},{\"season\":1,\"episode\":2,\"name\":\"episode-1-2\",\"airDate\":\"2010-02-07\"},{\"season\":2,\"episode\":1,\"name\":\"episode-2-1\",\"airDate\":\"2010-09-10\"},{\"season\":2,\"episode\":2,\"name\":\"episode-2-2\",\"airDate\":\"2012-01-03\"}]"
}

@test "10 - tvdb-get-series-episode-details INT : where ignoring cache and series found and no season or episode number provided should return episode details for all episodes in all seasons from API" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":1,\"name\":\"episode-1-1\",\"airDate\":\"2012-01-03\"},{\"season\":1,\"episode\":2,\"name\":\"episode-1-2\",\"airDate\":\"2015-01-03\"},{\"season\":2,\"episode\":1,\"name\":\"episode-2-1\",\"airDate\":\"2016-01-03\"},{\"season\":2,\"episode\":2,\"name\":\"episode-2-2\",\"airDate\":\"2012-01-04\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 --ignore-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\",\"airDate\":\"2002-09-20\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\",\"airDate\":\"2005-09-30\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\",\"airDate\":\"2002-09-27\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\",\"airDate\":\"2003-12-09\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\",\"airDate\":\"2006-07-28\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\",\"airDate\":\"2002-10-18\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\",\"airDate\":\"2012-11-11\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\",\"airDate\":\"2002-10-25\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\",\"airDate\":\"2002-11-01\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\",\"airDate\":\"2002-11-08\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\",\"airDate\":\"2002-11-15\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\",\"airDate\":\"2002-12-06\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\",\"airDate\":\"2002-12-13\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\",\"airDate\":\"2002-12-20\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\",\"airDate\":\"2003-06-23\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\",\"airDate\":\"2003-07-21\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\",\"airDate\":\"2003-07-28\"}]"
}

@test "11 - tvdb-get-series-episode-details INT : use-cache is the default" {
	fakeCacheFile="$CACHE_DIRECTORY/.71470"
	echo "[{\"season\":2,\"episode\":1,\"name\":\"A Cached copy of the name\",\"airDate\":\"2005-01-09\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 2 1
	assert_success
	assert_output "[{\"season\":2,\"episode\":1,\"name\":\"A Cached copy of the name\",\"airDate\":\"2005-01-09\"}]"
}

@test "12 - tvdb-get-series-episode-details INT : where using cache and no cached file exists should return episode details from API" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3  --use-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"}]"

	assert [ ! -e "$CACHE_DIRECTORY/.78874" ]
}

@test "13 - tvdb-get-series-episode-details INT : where ignoring cache and cached file exists should return episode details from API" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":3,\"name\":\"Stupid McStupid Head\",\"airDate\":\"2055-01-09\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3 --ignore-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"}]"

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileContents=$(cat "$CACHE_DIRECTORY/.78874")
	assert [ "$cachedFileContents" == "[{\"season\":1,\"episode\":3,\"name\":\"Stupid McStupid Head\",\"airDate\":\"2055-01-09\"}]" ]
}

@test "14 - tvdb-get-series-episode-details INT : where using cache and saving to cache and no cached file exists should return episode details from API and save series details in cache" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3 --use-cache --update-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"}]"

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileDetails=$(cat "$CACHE_DIRECTORY/.78874")
	assert [ "$cachedFileDetails" == "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\",\"airDate\":\"2002-09-20\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\",\"airDate\":\"2005-09-30\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\",\"airDate\":\"2002-09-27\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\",\"airDate\":\"2003-12-09\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\",\"airDate\":\"2006-07-28\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\",\"airDate\":\"2002-10-18\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\",\"airDate\":\"2012-11-11\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\",\"airDate\":\"2002-10-25\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\",\"airDate\":\"2002-11-01\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\",\"airDate\":\"2002-11-08\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\",\"airDate\":\"2002-11-15\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\",\"airDate\":\"2002-12-06\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\",\"airDate\":\"2002-12-13\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\",\"airDate\":\"2002-12-20\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\",\"airDate\":\"2003-06-23\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\",\"airDate\":\"2003-07-21\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\",\"airDate\":\"2003-07-28\"}]" ]
}

@test "15 - tvdb-get-series-episode-details INT : where ignoring cache and cached file exists and saving to cache should return episode details from API and save series details in cache" {
	fakeCacheFile="$CACHE_DIRECTORY/.78874"
	echo "[{\"season\":1,\"episode\":3,\"name\":\"Stupid McStupid Head\",\"airDate\":\"2006-10-10\"}]" > "$fakeCacheFile"

	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 78874 1 3 --ignore-cache --update-cache
	assert_success
	assert_output "[{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"}]"

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileDetails=$(cat "$CACHE_DIRECTORY/.78874")
	assert [ "$cachedFileDetails" == "[{\"season\":1,\"episode\":1,\"name\":\"The Train Job\",\"airDate\":\"2002-09-20\"},{\"season\":0,\"episode\":1,\"name\":\"Serenity\",\"airDate\":\"2005-09-30\"},{\"season\":1,\"episode\":2,\"name\":\"Bushwhacked\",\"airDate\":\"2002-09-27\"},{\"season\":0,\"episode\":2,\"name\":\"Here’s How It Was: The Making of “Firefly”\",\"airDate\":\"2003-12-09\"},{\"season\":1,\"episode\":3,\"name\":\"Our Mrs. Reynolds\",\"airDate\":\"2002-10-04\"},{\"season\":0,\"episode\":3,\"name\":\"Done the Impossible\",\"airDate\":\"2006-07-28\"},{\"season\":1,\"episode\":4,\"name\":\"Jaynestown\",\"airDate\":\"2002-10-18\"},{\"season\":0,\"episode\":4,\"name\":\"Browncoats Unite\",\"airDate\":\"2012-11-11\"},{\"season\":1,\"episode\":5,\"name\":\"Out of Gas\",\"airDate\":\"2002-10-25\"},{\"season\":1,\"episode\":6,\"name\":\"Shindig\",\"airDate\":\"2002-11-01\"},{\"season\":1,\"episode\":7,\"name\":\"Safe\",\"airDate\":\"2002-11-08\"},{\"season\":1,\"episode\":8,\"name\":\"Ariel\",\"airDate\":\"2002-11-15\"},{\"season\":1,\"episode\":9,\"name\":\"War Stories\",\"airDate\":\"2002-12-06\"},{\"season\":1,\"episode\":10,\"name\":\"Objects in Space\",\"airDate\":\"2002-12-13\"},{\"season\":1,\"episode\":11,\"name\":\"Serenity\",\"airDate\":\"2002-12-20\"},{\"season\":1,\"episode\":12,\"name\":\"Heart of Gold\",\"airDate\":\"2003-06-23\"},{\"season\":1,\"episode\":13,\"name\":\"Trash\",\"airDate\":\"2003-07-21\"},{\"season\":1,\"episode\":14,\"name\":\"The Message\",\"airDate\":\"2003-07-28\"}]" ]
}

@test "16 - tvdb-get-series-episode-details INT : updating cache and where requesting episode on second page of results, should return episode details as well as saving complete series to cache" {
	run "$UTILITIES_SRC_DIR"/tvdb-get-series-episode-details 71470 7 24 --ignore-cache --update-cache
	assert_success
	assert_output "[{\"season\":7,\"episode\":24,\"name\":\"Preemptive Strike\",\"airDate\":\"1994-05-16\"}]"

	assert [ -e "$CACHE_DIRECTORY/.71470" ]

	run cat "$CACHE_DIRECTORY/.71470"
	assert_output --regexp "\{\"season\":1,\"episode\":1,\"name\":\"Encounter at Farpoint \(1\)\",\"airDate\":\"1987-09-28\"\}"
	assert_output --regexp "\{\"season\":7,\"episode\":24,\"name\":\"Preemptive Strike\",\"airDate\":\"1994-05-16\"\}"
}
