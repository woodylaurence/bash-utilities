assert_json_equal() {
	local actual="$1"
	local expected="$2"

	if ! jq -e . <<< "$actual" >/dev/null 2>&1; then
		fail "actual output is not valid JSON: $actual"
	fi

	local diff=$(jq -n \
									--argjson expected "$expected" \
									--argjson actual "$actual" \
							'($expected | keys) as $expected_keys
									| ($actual | keys) as $actual_keys
									| ($expected_keys - $actual_keys) as $missing_keys
									| ($actual_keys - $expected_keys) as $extra_keys
									| ($expected_keys - $missing_keys) as $common_keys
									| {
											missing_keys: $missing_keys,
											extra_keys: $extra_keys,
											value_mismatches: [
												$common_keys[] | select($expected[.] != $actual[.])
																			| { key: ., expected: $expected[.], actual: $actual[.] }
											]
										}
							'
	)

	if jq -e '(.missing_keys | length == 0) and (.extra_keys | length == 0) and (.value_mismatches | length == 0)' <<< "$diff" >/dev/null; then
		return 0
	fi

	message=$(jq -r '
		def format_list(items):
			items | map("    - " + tostring) | join("\n");

		def format_mismatches(items):
			items | map(
				"    - " + .key + "\n"
				+ "        actual  : " + (.actual | tostring) + "\n"
				+ "        expected: " + (.expected | tostring)
			) | join("\n");

		[
			(if (.missing_keys | length) > 0 then
				"  missing keys:\n" + format_list(.missing_keys)
			else empty end),
			(if (.extra_keys | length) > 0 then
				"  extra keys:\n" + format_list(.extra_keys)
			else empty end),
			(if (.value_mismatches | length) > 0 then
				"  value mismatches:\n" + format_mismatches(.value_mismatches)
			else empty end)
		] | join("\n\n")
	' <<< "$diff")

	fail "$(printf 'JSON mismatch:\n\n%s' "$message")"
}