#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

SCRIPTS_SRC_DIR="../../../src/scripts"
UTILITIES_SRC_DIR="../../../src/utilities"
MEDIA_TEST_DIRECTORY="media-test-directory"

ORIGINAL_PATH_VARIABLE=$PATH

setup() {
	PATH="$PATH:$UTILITIES_SRC_DIR"

	mkdir $MEDIA_TEST_DIRECTORY
	pushd "$MEDIA_TEST_DIRECTORY" > /dev/null
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"

	popd > /dev/null
	rm -rf "$MEDIA_TEST_DIRECTORY"
}

@test "rename_tv_shows INT : non .mkv file should not be touched" {
	fakeFileName="fake-file.txt"
	touch $fakeFileName

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success

	assert [ ! -e original-media/ ]
	assert [ ! -e unmatched-media/ ]
	assert [ ! -e renamed-media/ ]
	assert [ -e $fakeFileName ]
}

@test "rename_tv_shows INT : cannot find series on tvdb should not try and rename show" {
	fakeFileName="StarWarsTrek_S01E01.mkv"
	touch "$fakeFileName"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success

	assert [ -e "original-media/$fakeFileName" ]
	assert [ -e "unmatched-media/$fakeFileName" ]
	assert [ "$(ls -A renamed-media)" ]

	assert_failure
	assert_output "ERROR: No series search term provided."
}
