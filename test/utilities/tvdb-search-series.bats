#!/bin/bash

load ../helpers/mocks/stub
load ../helpers/bats-support/load
load ../helpers/bats-assert/load
load ../helpers/custom-assert-helpers

@test "1 - tvdb-search-series : no search term provided should error" {
	run tvdb-search-series

	assert_failure
	assert_output --partial "ERROR - No series search term provided."
}

@test "2 - tvdb-search-series : no series found should return null" {
	run tvdb-search-series "fake-series-187o6478"

	assert_success
	assert_json_equal "$output" '[]'
}

@test "3 - tvdb-search-series : where exact match with single series found should return json with series name and id" {
	run tvdb-search-series "Star Trek: The Next Generation"

	assert_success
	assert_json_equal "$output" '[
		{
			"name": "Star Trek: The Next Generation",
			"id": "71470",
			"release_year": "1987",
			"overview": "A century after Captain Kirk'\''s five year mission, the next generation of Starfleet officers begins their journey aboard the new flagship of the Federation.\r\n\r\nCommanded by Captain Jean-Luc Picard the Galaxy class starship Enterprise NCC-1701-D will seek out new life and new civilizations - to boldly go where no one has gone before."
		}
	]'
}

@test "4 - tvdb-search-series : where match found with single series found should return json with series name and id" {
	run tvdb-search-series "Star Trek The Next Generation"

	assert_success
	assert_json_equal "$output" '[
		{
			"name": "Star Trek: The Next Generation",
			"id": "71470",
			"release_year": "1987",
			"overview": "A century after Captain Kirk'\''s five year mission, the next generation of Starfleet officers begins their journey aboard the new flagship of the Federation.\r\n\r\nCommanded by Captain Jean-Luc Picard the Galaxy class starship Enterprise NCC-1701-D will seek out new life and new civilizations - to boldly go where no one has gone before."
		}
	]'
}

@test "5 - tvdb-search-series : where multiple matches found should return json with list of series name and id" {
	run tvdb-search-series "Babylon 5"

	assert_success
	assert_json_equal "$output" '[
		{
			"name": "Babylon 5",
			"id": "70726",
			"release_year": "1994",
			"overview": "Babylon 5 is a five-mile long space station located in neutral space. Built by the Earth Alliance in the 2250s, its goal is to maintain peace among the various alien races by providing a sanctuary where grievances and negotiations can be worked out among duly appointed ambassadors. A council made up of representatives from the five major space-faring civilizations - the Earth Alliance, Minbari Federation, Centauri Republic, Narn Regime, and Vorlon Empire - work with the League of Non-Aligned Worlds to keep interstellar relations under control. Aside from its diplomatic function, Babylon 5 also serves as a military post for Earth and a port of call for travelers, traders, businessmen, criminals, and Rangers."
		},
		{
			"name": "Crusade",
			"id": "71790",
			"release_year": "1999",
			"overview": "Crusade, a spin-off from the Emmy-winning Babylon 5, describes the efforts of the Interstellar Alliance vessel Excalibur to find the cure to a plague released on Earth. This plague of nano-viruses, released by the Shadow'\''s servants the Drakh in retaliation for the Shadow War will kill all mammalian life on Earth within five years if the cure is not found."
		}
	]'
}
