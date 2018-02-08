#!/bin/bash

load ../helpers/bats-support/load
load ../helpers/bats-assert/load

SCRIPTS_SRC_DIR="../../src/scripts"
UTILITIES_SRC_DIR="../../src/utilities"
MEDIA_TEST_DIRECTORY=$(readlink -f "media-test-directory")

ORIGINAL_PATH_VARIABLE=$PATH
ORIGINAL_MEDIA_CENTRE_HOST=$MEDIA_CENTRE_HOST
ORIGINAL_MEDIA_CENTRE_TV_SHOW_DIRECTORY=$MEDIA_CENTRE_TV_SHOW_DIRECTORY

setup() {
	if [[ -z "$LOCAL_HOST" ]]; then
		assert_failure "LOCAL_HOST variable is not set."
	fi
	if [[ -z "$MEDIA_CENTRE_HOST" ]]; then
		assert_failure "MEDIA_CENTRE_HOST variable is not set."
	fi
	if [[ -z "$MEDIA_CENTRE_TV_SHOW_DIRECTORY" ]]; then
		assert_failure "MEDIA_CENTRE_TV_SHOW_DIRECTORY variable is not set."
	fi

	PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")
	MEDIA_CENTRE_HOST="$LOCAL_HOST"
	MEDIA_CENTRE_TV_SHOW_DIRECTORY="$MEDIA_TEST_DIRECTORY"
	mkdir $MEDIA_TEST_DIRECTORY
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"
	MEDIA_CENTRE_HOST="$ORIGINAL_MEDIA_CENTRE_HOST"
	MEDIA_CENTRE_TV_SHOW_DIRECTORY="$ORIGINAL_MEDIA_CENTRE_TV_SHOW_DIRECTORY"

	rm -rf "$MEDIA_TEST_DIRECTORY"
}

@test "1 - find_new_episodes UNIT : not providing any series to check should error" {
	run "$SCRIPTS_SRC_DIR"/find_new_episodes.sh
	assert_failure
	assert_output "ERROR: no series provided"
}

@test "2 - find_new_episodes INT : providing one series which I do not have should list all episodes in series" {
	run "$SCRIPTS_SRC_DIR"/find_new_episodes.sh "Firefly"
	assert_success
	assert_output "Firefly:
-----------
Season 1 Episode 1 is available (aired 20/Sep/2002)
Season 1 Episode 2 is available (aired 27/Sep/2002)
Season 1 Episode 3 is available (aired 04/Oct/2002)
Season 1 Episode 4 is available (aired 18/Oct/2002)
Season 1 Episode 5 is available (aired 25/Oct/2002)
Season 1 Episode 6 is available (aired 01/Nov/2002)
Season 1 Episode 7 is available (aired 08/Nov/2002)
Season 1 Episode 8 is available (aired 15/Nov/2002)
Season 1 Episode 9 is available (aired 06/Dec/2002)
Season 1 Episode 10 is available (aired 13/Dec/2002)
Season 1 Episode 11 is available (aired 20/Dec/2002)
Season 1 Episode 12 is available (aired 23/Jun/2003)
Season 1 Episode 13 is available (aired 21/Jul/2003)
Season 1 Episode 14 is available (aired 28/Jul/2003)"
}

@test "3 - find_new_episodes INT : providing one series which I have some episodes in latest season should return all episodes after latest episode" {
	mkdir "$MEDIA_TEST_DIRECTORY/Firefly"
	mkdir "$MEDIA_TEST_DIRECTORY/Firefly/Season 1"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/01 Episode 1.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/02 Episode 2.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/06 Episode 6.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/07 Episode 7.mp4"

	run "$SCRIPTS_SRC_DIR"/find_new_episodes.sh "Firefly"
	assert_success
	assert_output "Firefly:
-----------
Season 1 Episode 8 is available (aired 15/Nov/2002)
Season 1 Episode 9 is available (aired 06/Dec/2002)
Season 1 Episode 10 is available (aired 13/Dec/2002)
Season 1 Episode 11 is available (aired 20/Dec/2002)
Season 1 Episode 12 is available (aired 23/Jun/2003)
Season 1 Episode 13 is available (aired 21/Jul/2003)
Season 1 Episode 14 is available (aired 28/Jul/2003)"
}

@test "4 - find_new_episodes INT : providing one series which I have some episodes in non-latest season should return all episodes after latest episode" {
	mkdir "$MEDIA_TEST_DIRECTORY/The Thin Blue Line"
	mkdir "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1"
	touch "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1/01 Episode 1.mp4"
	touch "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1/02 Episode 2.mp4"
	touch "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1/03 Episode 3.mp4"
	touch "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1/04 Episode 4.mp4"

	run "$SCRIPTS_SRC_DIR"/find_new_episodes.sh "The Thin Blue Line"
	assert_success
	assert_output "The Thin Blue Line:
----------------------
Season 1 Episode 5 is available (aired 11/Dec/1995)
Season 1 Episode 6 is available (aired 18/Dec/1995)
Season 1 Episode 7 is available (aired 26/Dec/1995)

Season 2 Episode 1 is available (aired 14/Nov/1996)
Season 2 Episode 2 is available (aired 21/Nov/1996)
Season 2 Episode 3 is available (aired 28/Nov/1996)
Season 2 Episode 4 is available (aired 05/Dec/1996)
Season 2 Episode 5 is available (aired 12/Dec/1996)
Season 2 Episode 6 is available (aired 19/Dec/1996)
Season 2 Episode 7 is available (aired 23/Dec/1996)"
}

@test "5 - find_new_episodes INT : providing single series which I have all episodes of should say no available episodes" {
	mkdir "$MEDIA_TEST_DIRECTORY/Firefly"
	mkdir "$MEDIA_TEST_DIRECTORY/Firefly/Season 1"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/01 Episode 1.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/02 Episode 2.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/06 Episode 6.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/07 Episode 7.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/11 Episode 11.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/12 Episode 12.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/13 Episode 13.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/14 Episode 14.mp4"

	run "$SCRIPTS_SRC_DIR"/find_new_episodes.sh "Firefly"
	assert_success
	assert_output "Firefly:
-----------
No data available on next episode"
}

@test "6 - find_new_episodes INT : providing single series which I have all aired episodes of but new episode exists but not yet aired" {
	assert_failure
	assert_output "Haven't yet tested this as it involves messing with system clock."
}

@test "7 - find_new_episodes INT : providing multiple series should return new episodes available ordered by series title" {
	mkdir "$MEDIA_TEST_DIRECTORY/Firefly"
	mkdir "$MEDIA_TEST_DIRECTORY/Firefly/Season 1"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/01 Episode 1.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/02 Episode 2.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/06 Episode 6.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/07 Episode 7.mp4"
	touch "$MEDIA_TEST_DIRECTORY/Firefly/Season 1/11 Episode 11.mp4"

	mkdir "$MEDIA_TEST_DIRECTORY/The Thin Blue Line"
	mkdir "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1"
	touch "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1/01 Episode 1.mp4"
	touch "$MEDIA_TEST_DIRECTORY/The Thin Blue Line/Season 1/06 Episode 3.mp4"

	run "$SCRIPTS_SRC_DIR"/find_new_episodes.sh "The Thin Blue Line;Firefly"
	assert_success
	assert_output "Firefly:
-----------
Season 1 Episode 12 is available (aired 23/Jun/2003)
Season 1 Episode 13 is available (aired 21/Jul/2003)
Season 1 Episode 14 is available (aired 28/Jul/2003)


The Thin Blue Line:
----------------------
Season 1 Episode 7 is available (aired 26/Dec/1995)

Season 2 Episode 1 is available (aired 14/Nov/1996)
Season 2 Episode 2 is available (aired 21/Nov/1996)
Season 2 Episode 3 is available (aired 28/Nov/1996)
Season 2 Episode 4 is available (aired 05/Dec/1996)
Season 2 Episode 5 is available (aired 12/Dec/1996)
Season 2 Episode 6 is available (aired 19/Dec/1996)
Season 2 Episode 7 is available (aired 23/Dec/1996)"
}
