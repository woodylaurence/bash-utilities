#!/usr/bin/env bats

load helpers/bats-assert/load

UTILITIES_SRC_DIR="../../src/utilities";

@test "getMonthAsNum passing in 'Jan'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Jan)
  assert_equal "$actual" "01"
}

@test "getMonthAsNum passing in 'January'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber January)
  assert_equal "$actual" "01"
}

@test "getMonthAsNum passing in 'Feb'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Feb)
  assert_equal "$actual" "02"
}

@test "getMonthAsNum passing in 'February'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber February)
  assert_equal "$actual" "02"
}

@test "getMonthAsNum passing in 'Mar'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Mar)
  assert_equal "$actual" "03"
}

@test "getMonthAsNum passing in 'March'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber March)
  assert_equal "$actual" "03"
}

@test "getMonthAsNum passing in 'Apr'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Apr)
  assert_equal "$actual" "04"
}

@test "getMonthAsNum passing in 'April'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber April)
  assert_equal "$actual" "04"
}

@test "getMonthAsNum passing in 'May'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber May)
  assert_equal "$actual" "05"
}

@test "getMonthAsNum passing in 'Jun'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Jun)
  assert_equal "$actual" "06"
}

@test "getMonthAsNum passing in 'June'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber June)
  assert_equal "$actual" "06"
}

@test "getMonthAsNum passing in 'Jul'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Jul)
  assert_equal "$actual" "07"
}

@test "getMonthAsNum passing in 'July'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber July)
  assert_equal "$actual" "07"
}

@test "getMonthAsNum passing in 'Aug'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Aug)
  assert_equal "$actual" "08"
}

@test "getMonthAsNum passing in 'August'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber August)
  assert_equal "$actual" "08"
}

@test "getMonthAsNum passing in 'Sep'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Sep)
  assert_equal "$actual" "09"
}

@test "getMonthAsNum passing in 'September'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber September)
  assert_equal "$actual" "09"
}

@test "getMonthAsNum passing in 'Oct'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Oct)
  assert_equal "$actual" "10"
}

@test "getMonthAsNum passing in 'October'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber October)
  assert_equal "$actual" "10"
}

@test "getMonthAsNum passing in 'Nov'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Nov)
  assert_equal "$actual" "11"
}

@test "getMonthAsNum passing in 'November'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber November)
  assert_equal "$actual" "11"
}

@test "getMonthAsNum passing in 'Dec'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber Dec)
  assert_equal "$actual" "12"
}

@test "getMonthAsNum passing in 'December'" {
  actual=$("${UTILITIES_SRC_DIR}"/getMonthAsNumber December)
  assert_equal "$actual" "12"
}
