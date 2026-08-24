#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load
load ../helpers/custom-assert-helpers

ORIGINAL_PATH_VARIABLE=$PATH
CACHE_DIRECTORY="/tmp/usr/tvdb-cache"
TMP_STORAGE_DIRECTORY="/tmp/usr/tmp_store"

setup() {
	if [[ -e "$CACHE_DIRECTORY" ]]; then
		mv "$CACHE_DIRECTORY" "${CACHE_DIRECTORY}.bak"
	fi
	mkdir -p "$CACHE_DIRECTORY"
}

teardown() {
	rm -rf "$CACHE_DIRECTORY"

	if [[ -e "${CACHE_DIRECTORY}.bak" ]]; then
		mv "${CACHE_DIRECTORY}.bak" "$CACHE_DIRECTORY"
	fi
}

@test "1 - tvdb-get-series-episode-details : where no series id provided should error" {
	run tvdb-get-series-episode-details

	assert_failure
	assert_output --partial "ERROR - No series id provided."
}

@test "2 - tvdb-get-series-episode-details : where skipping cache and series found and season number and episode number provided but episode doesnt exist and should return null" {
	run tvdb-get-series-episode-details 71470 1 78 --skip-cache

	assert_success
	assert_output "null"
}

@test "3 - tvdb-get-series-episode-details : where using cache and series found in cache and season number and episode number provided but episode doesnt exist and doesnt exist online should return null" {
	cat <<EOF > "$CACHE_DIRECTORY/.219631"
	[
		{
			"season": 1,
			"episode": 1,
			"name": "The Mammy",
			"airDate": "2011-01-01"
		},
		{
			"season": 1,
			"episode": 2,
			"name": "Mammy's Secret",
			"airDate": "2011-01-08"
		}
	]
EOF

	run tvdb-get-series-episode-details 219631 1 78

	assert_success
	assert_output "null"
}

@test "4 - tvdb-get-series-episode-details : where using cache and series found in cache and season number and episode number provided but episode doesnt exist in cache but does exist online should return episode details" {
	cat <<EOF > "$CACHE_DIRECTORY/.219631"
	[
		{
			"season": 1,
			"episode": 1,
			"name": "The Mammy",
			"airDate": "2011-01-01"
		},
		{
			"season": 1,
			"episode": 2,
			"name": "Mammy's Secret",
			"airDate": "2011-01-08"
		}
	]
EOF

	run tvdb-get-series-episode-details 219631 1 4

	assert_success
	assert_json_equal "$output" '{

			"season": 1,

		"episode": 4,
		"name": "Mammy Rides Again"
	}'
}

@test "5 - tvdb-get-series-episode-details : where using cache and series found and season number and episode number provided should return episode details from cache" {
	cat <<EOF > "$CACHE_DIRECTORY/.71470"
	[
		{
			"season": 3,
			"episode": 7,
			"name": "A Cached copy of the name"
		}
	]
EOF

	run tvdb-get-series-episode-details 71470 3 7

	assert_success
	assert_json_equal "$output" '{
		"season": 3,
		"episode": 7,
		"name": "A Cached copy of the name"
	}'
}

@test "6 - tvdb-get-series-episode-details : where skipping cache and series found and season number and episode number provided should return episode details from TVDB" {
	cat <<EOF > "$CACHE_DIRECTORY/.71470"
	[
		{
			"season": 3,
			"episode": 7,
			"name": "A Cached copy of the name"
		}
	]
EOF

	run tvdb-get-series-episode-details 71470 3 7 --skip-cache

	assert_success
	assert_json_equal "$output" '{
		"season": 3,
		"episode": 7,
		"name": "The Enemy"
	}'
}

@test "7 - tvdb-get-series-episode-details : where using cache and series found and season number provided should return episode details for all episodes in season from cache" {
	cat <<EOF > "$CACHE_DIRECTORY/.176941"
	[
		{
			"season": 2,
			"episode": 1,
			"name": "Episode-2-1"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "Episode-2-2"
		},
		{
			"season": 3,
			"episode": 1,
			"name": "Episode-3-1"
		}
	]
EOF

	run tvdb-get-series-episode-details 176941 2

	assert_success
	assert_json_equal "$output" '[
		{
			"season": 2,
			"episode": 1,
			"name": "Episode-2-1"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "Episode-2-2"
		}
	]'
}

@test "8 - tvdb-get-series-episode-details : where skipping cache and series found and season number provided should return episode details for all episodes in season from API" {
	cat <<EOF > "$CACHE_DIRECTORY/.176941"
	[
		{
			"season": 2,
			"episode": 1,
			"name": "Episode-2-1"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "Episode-2-2"
		},
		{
			"season": 3,
			"episode": 1,
			"name": "Episode-3-1"
		}
	]
EOF

	run tvdb-get-series-episode-details 176941 2 --skip-cache

	assert_success
	assert_json_equal "$output" '[
		{
			"season": 2,
			"episode": 1,
			"name": "A Scandal in Belgravia"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "The Hounds of Baskerville"
		},
		{
			"season": 2,
			"episode": 3,
			"name": "The Reichenbach Fall"
		}
	]'
}

@test "9 - tvdb-get-series-episode-details : where using cache and series found and no season or episode number provided should return episode details for all episodes in all seasons from cache" {
	cat <<EOF > "$CACHE_DIRECTORY/.78874"
	[
		{
			"season": 1,
			"episode": 1,
			"name": "episode-1-1"
		},
		{
			"season": 1,
			"episode": 2,
			"name": "episode-1-2"
		},
		{
			"season": 2,
			"episode": 1,
			"name": "episode-2-1"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "episode-2-2"
		}
	]
EOF

	run tvdb-get-series-episode-details 78874

	assert_success
	assert_json_equal "$output" '[
		{
			"season": 1,
			"episode": 1,
			"name": "episode-1-1"
		},
		{
			"season": 1,
			"episode": 2,
			"name": "episode-1-2"
		},
		{
			"season": 2,
			"episode": 1,
			"name": "episode-2-1"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "episode-2-2"
		}
	]'
}

@test "10 - tvdb-get-series-episode-details : where skipping cache and series found and no season or episode number provided should return episode details for all episodes in all seasons from API" {
	cat <<EOF > "$CACHE_DIRECTORY/.78874"
	[
		{
			"season": 1,
			"episode": 1,
			"name": "episode-1-1"
		},
		{
			"season": 1,
			"episode": 2,
			"name": "episode-1-2"
		},
		{
			"season": 2,
			"episode": 1,
			"name": "episode-2-1"
		},
		{
			"season": 2,
			"episode": 2,
			"name": "episode-2-2"
		}
	]
EOF

	run tvdb-get-series-episode-details 78874 --skip-cache

	assert_success
	assert_json_equal "$output" '[
		{
			"season": 0,
			"episode": 1,
			"name": "Serenity"
		},
		{
			"season": 0,
			"episode": 2,
			"name": "Done the Impossible"
		},
		{
			"season": 0,
			"episode": 3,
			"name": "Browncoats Unite"
		},
		{
			"season": 0,
			"episode": 4,
			"name": "R. Tam Sessions"
		},
		{
			"season": 0,
			"episode": 5,
			"name": "Here'\''s How It Was: The Making of '\''Firefly'\''"
		},
		{
			"season": 0,
			"episode": 6,
			"name": "Serenity: The 10th Character"
		},
		{
			"season": 1,
			"episode": 1,
			"name": "The Train Job"
		},
		{
			"season": 1,
			"episode": 2,
			"name": "Bushwhacked"
		},
		{
			"season": 1,
			"episode": 3,
			"name": "Our Mrs. Reynolds"
		},
		{
			"season": 1,
			"episode": 4,
			"name": "Jaynestown"
		},
		{
			"season": 1,
			"episode": 5,
			"name": "Out of Gas"
		},
		{
			"season": 1,
			"episode": 6,
			"name": "Shindig"
		},
		{
			"season": 1,
			"episode": 7,
			"name": "Safe"
		},
		{
			"season": 1,
			"episode": 8,
			"name": "Ariel"
		},
		{
			"season": 1,
			"episode": 9,
			"name": "War Stories"
		},
		{
			"season": 1,
			"episode": 10,
			"name": "Objects in Space"
		},
		{
			"season": 1,
			"episode": 11,
			"name": "Serenity"
		},
		{
			"season": 1,
			"episode": 12,
			"name": "Heart of Gold"
		},
		{
			"season": 1,
			"episode": 13,
			"name": "Trash"
		},
		{
			"season": 1,
			"episode": 14,
			"name": "The Message"
		}
	]'
}

@test "11 - tvdb-get-series-episode-details : where using cache and no cached file exists should return episode details from API" {
	run tvdb-get-series-episode-details 78874 1 3

	assert_success
	assert_json_equal "$output" '{
		"season": 1,
		"episode": 3,
		"name": "Our Mrs. Reynolds"
	}'

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
}

@test "12 - tvdb-get-series-episode-details : where using cache and no cached file exists should return episode deatils from cache on second request" {
	run tvdb-get-series-episode-details 78874 1 3

	assert_success
	assert [ -e "$CACHE_DIRECTORY/.78874" ]

	sed -i 's/Our Mrs. Reynolds/Cached Title/g' "$CACHE_DIRECTORY/.78874"
	run tvdb-get-series-episode-details 78874 1 3

	assert_success
	assert_json_equal "$output" '{
		"season": 1,
		"episode": 3,
		"name": "Cached Title"
	}'
}

@test "13 - tvdb-get-series-episode-details : where skipping cache and cached file exists should return episode details from API" {
	cat <<EOF > "$CACHE_DIRECTORY/.78874"
	[
		{
			"season": 1,
			"episode": 3,
			"name": "Stupid McStupid Head"
		}
	]
EOF

	run tvdb-get-series-episode-details 78874 1 3 --skip-cache

	assert_success
	assert_json_equal "$output" '{
		"season": 1,
		"episode": 3,
		"name": "Our Mrs. Reynolds"
	}'

	assert [ -e "$CACHE_DIRECTORY/.78874" ]
	cachedFileContents=$(cat "$CACHE_DIRECTORY/.78874")
	assert_json_equal "$cachedFileContents" '[
		{
			"season": 1,
			"episode": 3,
			"name": "Stupid McStupid Head"
		}
	]'
}

@test "14 - tvdb-get-series-episode-details : requesting episode on second page of results, should return episode details" {
	run tvdb-get-series-episode-details 71663 30 1

	assert_success
	assert_json_equal "$output" '{
		"season": 30,
		"episode": 1,
		"name": "Bart'\''s Not Dead"
	}'

	assert [ -e "$CACHE_DIRECTORY/.71663" ]

	run cat "$CACHE_DIRECTORY/.71663"
	assert_output --regexp '\{"season":1,"episode":1,"name":"Simpsons Roasting on an Open Fire"\}'
	assert_output --regexp '\{"season":30,"episode":1,"name":"Bart'\''s Not Dead"\}'
}
