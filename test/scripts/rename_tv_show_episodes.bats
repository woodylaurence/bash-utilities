#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

SCRIPTS_SRC_DIR="../../../src/scripts"
UTILITIES_SRC_DIR="../../../src/utilities"
MEDIA_TEST_DIRECTORY="media-test-directory"

ORIGINAL_PATH_VARIABLE=$PATH
CACHED_SERIES_NAME_TO_ID_FILE="/tmp/usr/tvdb-cache/.series-name-id-cache"

setup() {
	PATH=$(echo "$PATH" | sed -r "s|/usr/local/bin|$UTILITIES_SRC_DIR|")

	mkdir $MEDIA_TEST_DIRECTORY
	pushd "$MEDIA_TEST_DIRECTORY" > /dev/null

	if [[ -e "$CACHED_SERIES_NAME_TO_ID_FILE" ]]; then
		mv "$CACHED_SERIES_NAME_TO_ID_FILE" "${CACHED_SERIES_NAME_TO_ID_FILE}.moved"
	fi
}

teardown() {
	PATH="$ORIGINAL_PATH_VARIABLE"

	popd > /dev/null
	rm -rf "$MEDIA_TEST_DIRECTORY"

	if [[ -e "${CACHED_SERIES_NAME_TO_ID_FILE}.moved" ]]; then
		mv "${CACHED_SERIES_NAME_TO_ID_FILE}.moved" "$CACHED_SERIES_NAME_TO_ID_FILE"
	fi
}

@test "1 - rename_tv_show_episodes UNIT : original-media folder exists should error" {
	mkdir original-media

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_failure
	assert_output "ERROR: original-media folder exists in current directory."
}

@test "2 - rename_tv_show_episodes UNIT : unmatched-media folder exists should error" {
	mkdir unmatched-media

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_failure
	assert_output "ERROR: unmatched-media folder exists in current directory."
}

@test "3 - rename_tv_show_episodes UNIT : renamed-media folder exists should error" {
	mkdir renamed-media

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_failure
	assert_output "ERROR: renamed-media folder exists in current directory."
}

@test "4 - rename_tv_show_episodes UNIT : no media files in directory" {
	touch "fake-file.txt"
	touch "TheHobbitAnUnexpectedJourney.mkv"
	touch "TheHobbitTheDesolationOfSmaug.m4v"
	touch "TheHobbitTheBattleOfTheFiveArmies.mp4"
	touch "HarryPotterAndThePrisonerOfAzkaban.avi"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_failure
	assert_output "ERROR: No media files found in current directory."

	assert [ ! -e original-media/ ]
	assert [ ! -e unmatched-media/ ]
	assert [ ! -e renamed-media/ ]
	assert [ -e $fakeFileName ]
}

@test "5 - rename_tv_show_episodes INT : cannot find series on tvdb should not try and rename show" {
	fakeFileName="StarWarsTheNextGeneration_S01E01.mkv"
	touch "$fakeFileName"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Unable to rename the following files:
 - StarWarsTheNextGeneration_S01E01.mkv (series search term - 'star wars the next generation')
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName" ]
	assert [ -e "unmatched-media/$fakeFileName" ]
	assert [ -z "$(ls -A renamed-media)" ]
	assert [ ! -e "$fakeFileName" ]
}

@test "6 - rename_tv_show_episodes INT : should process .m4v, .mkv, .avi, .mp4 files" {
	fakeFileName1="StarWarsTheNextGeneration_S01E01.mkv"
	fakeFileName2="StarWarsTheNextGeneration_S01E01.m4v"
	fakeFileName3="StarWarsTheNextGeneration_S01E01.mp4"
	fakeFileName4="StarWarsTheNextGeneration_S01E01.avi"

	touch "$fakeFileName1"
	touch "$fakeFileName2"
	touch "$fakeFileName3"
	touch "$fakeFileName4"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Unable to rename the following files:
 - StarWarsTheNextGeneration_S01E01.mkv (series search term - 'star wars the next generation')
 - StarWarsTheNextGeneration_S01E01.m4v (series search term - 'star wars the next generation')
 - StarWarsTheNextGeneration_S01E01.mp4 (series search term - 'star wars the next generation')
 - StarWarsTheNextGeneration_S01E01.avi (series search term - 'star wars the next generation')
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName1" ]
	assert [ -e "original-media/$fakeFileName2" ]
	assert [ -e "original-media/$fakeFileName3" ]
	assert [ -e "original-media/$fakeFileName4" ]

	assert [ -e "unmatched-media/$fakeFileName1" ]
	assert [ -e "unmatched-media/$fakeFileName2" ]
	assert [ -e "unmatched-media/$fakeFileName3" ]
	assert [ -e "unmatched-media/$fakeFileName4" ]

	assert [ -z "$(ls -A renamed-media)" ]

	assert [ ! -e "$fakeFileName1" ]
	assert [ ! -e "$fakeFileName2" ]
	assert [ ! -e "$fakeFileName3" ]
	assert [ ! -e "$fakeFileName4" ]
}

@test "7 - rename_tv_show_episodes INT : series found, non existent season or episode should not try and rename show" {
	fakeFileName="StarTrekTheNextGeneration_S19E25.mkv"
	touch "$fakeFileName"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Unable to rename the following files:
 - StarTrekTheNextGeneration_S19E25.mkv (series search term - 'star trek the next generation')
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName" ]
	assert [ -e "unmatched-media/$fakeFileName" ]
	assert [ -z "$(ls -A renamed-media)" ]
	assert [ ! -e "$fakeFileName" ]
}

@test "8 - rename_tv_show_episodes INT : series found and season and episode exist should rename show" {
	fakeFileName="StarTrekTheNextGeneration_S04E15.mkv"
	touch "$fakeFileName"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Renamed the following files:
 - StarTrekTheNextGeneration_S04E15.mkv --> 15 First Contact.mkv (Star Trek The Next Generation/Season 4)
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName" ]
	assert [ -z "$(ls -A unmatched-media)" ]
	assert [ -e "renamed-media/Star Trek The Next Generation/Season 4/15 First Contact.mkv" ]
	assert [ ! -e "$fakeFileName" ]
}

@test "9 - rename_tv_show_episodes INT : should output series in alphabetical order, separated by new lines" {
	fakeFileName1="StarTrekTheNextGeneration_S04E15.mkv"
	fakeFileName2="TheBigBangTheory_S10E16.m4v"
	fakeFileName3="HowIMetYourMother_S03E02.mp4"
	fakeFileName4="TheRickyGervaisShow_S01E05.avi"
	touch "$fakeFileName1"
	touch "$fakeFileName2"
	touch "$fakeFileName3"
	touch "$fakeFileName4"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Renamed the following files:
 - HowIMetYourMother_S03E02.mp4 --> 02 We're Not from Here.mp4 (How I Met Your Mother/Season 3)

 - StarTrekTheNextGeneration_S04E15.mkv --> 15 First Contact.mkv (Star Trek The Next Generation/Season 4)

 - TheBigBangTheory_S10E16.m4v --> 16 The Allowance Evaporation.m4v (The Big Bang Theory/Season 10)

 - TheRickyGervaisShow_S01E05.avi --> 05 Glass Houses.avi (The Ricky Gervais Show/Season 1)
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName1" ]
	assert [ -e "original-media/$fakeFileName2" ]
	assert [ -e "original-media/$fakeFileName3" ]
	assert [ -e "original-media/$fakeFileName4" ]

	assert [ -z "$(ls -A unmatched-media)" ]

	assert [ -e "renamed-media/Star Trek The Next Generation/Season 4/15 First Contact.mkv" ]
	assert [ -e "renamed-media/The Big Bang Theory/Season 10/16 The Allowance Evaporation.m4v" ]
	assert [ -e "renamed-media/How I Met Your Mother/Season 3/02 We're Not from Here.mp4" ]
	assert [ -e "renamed-media/The Ricky Gervais Show/Season 1/05 Glass Houses.avi" ]

	assert [ ! -e "$fakeFileName1" ]
	assert [ ! -e "$fakeFileName2" ]
	assert [ ! -e "$fakeFileName3" ]
	assert [ ! -e "$fakeFileName4" ]
}

@test "10 - rename_tv_show_episodes INT : should output episodes in season order then episode order" {
	fakeFileName1="StarTrekTheNextGeneration_S04E15.mkv"
	fakeFileName2="StarTrekTheNextGeneration_S03E18.mkv"
	fakeFileName3="StarTrekTheNextGeneration_S04E08.mkv"
	touch "$fakeFileName1"
	touch "$fakeFileName2"
	touch "$fakeFileName3"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Renamed the following files:
 - StarTrekTheNextGeneration_S03E18.mkv --> 18 Allegiance.mkv (Star Trek The Next Generation/Season 3)
 - StarTrekTheNextGeneration_S04E08.mkv --> 08 Future Imperfect.mkv (Star Trek The Next Generation/Season 4)
 - StarTrekTheNextGeneration_S04E15.mkv --> 15 First Contact.mkv (Star Trek The Next Generation/Season 4)
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName1" ]
	assert [ -e "original-media/$fakeFileName2" ]
	assert [ -e "original-media/$fakeFileName3" ]

	assert [ -z "$(ls -A unmatched-media)" ]

	assert [ -e "renamed-media/Star Trek The Next Generation/Season 4/15 First Contact.mkv" ]
	assert [ -e "renamed-media/Star Trek The Next Generation/Season 3/18 Allegiance.mkv" ]
	assert [ -e "renamed-media/Star Trek The Next Generation/Season 4/08 Future Imperfect.mkv" ]

	assert [ ! -e "$fakeFileName1" ]
	assert [ ! -e "$fakeFileName2" ]
	assert [ ! -e "$fakeFileName3" ]
}

@test "11 - rename_tv_show_episodes INT : some files matched, others not" {
	fakeFileName1="StarTrekTheNextGeneration_S04E15.mkv"
	fakeFileName2="HowIMetYourFather_S03E18.mkv"
	fakeFileName3="TheBigBangTheory_S04E08.m4v"
	fakeFileName4="TheBigBangTheory_S22E91.mkv"
	touch "$fakeFileName1"
	touch "$fakeFileName2"
	touch "$fakeFileName3"
	touch "$fakeFileName4"

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Renamed the following files:
 - StarTrekTheNextGeneration_S04E15.mkv --> 15 First Contact.mkv (Star Trek The Next Generation/Season 4)

 - TheBigBangTheory_S04E08.m4v --> 08 The 21-Second Excitation.m4v (The Big Bang Theory/Season 4)
--------------------------------------------

Unable to rename the following files:
 - HowIMetYourFather_S03E18.mkv (series search term - 'how i met your father')
 - TheBigBangTheory_S22E91.mkv (series search term - 'the big bang theory')
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName1" ]
	assert [ -e "original-media/$fakeFileName2" ]
	assert [ -e "original-media/$fakeFileName3" ]
	assert [ -e "original-media/$fakeFileName4" ]

	assert [ -e "unmatched-media/$fakeFileName2" ]
	assert [ -e "unmatched-media/$fakeFileName4" ]

	assert [ -e "renamed-media/Star Trek The Next Generation/Season 4/15 First Contact.mkv" ]
	assert [ -e "renamed-media/The Big Bang Theory/Season 4/08 The 21-Second Excitation.m4v" ]

	assert [ ! -e "$fakeFileName1" ]
	assert [ ! -e "$fakeFileName2" ]
	assert [ ! -e "$fakeFileName3" ]
}

@test "12 - rename_tv_show_episodes INT : where multiple results for series name but cached series-name to id file exists and contains series name" {
	fakeFileName="Psych_S04E15.mkv"
	touch "$fakeFileName"

	echo "[{\"seriesSearchTerm\":\"psych\",\"seriesId\":71470}]" > $CACHED_SERIES_NAME_TO_ID_FILE

	run "$SCRIPTS_SRC_DIR"/rename_tv_show_episodes.sh
	assert_success
	assert_output "

Renamed the following files:
 - Psych_S04E15.mkv --> 15 First Contact.mkv (Psych/Season 4)
--------------------------------------------"

	assert [ -e "original-media/$fakeFileName" ]
	assert [ -e "renamed-media/Psych/Season 4/15 First Contact.mkv" ]
	assert [ ! -e "$fakeFileName" ]
}
