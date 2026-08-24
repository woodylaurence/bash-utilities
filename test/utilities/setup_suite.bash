setup_suite() {
	export ORIGINAL_PATH="$PATH"
	export PATH="${PATH//:\/usr\/local\/bin/}"
  export PATH="${PATH//\/usr\/local\/bin:/}"
  export PATH="../../src/utilities:$PATH"
}

teardown_suite() {
	export PATH="$ORIGINAL_PATH"
}