#!/usr/bin/env bats

UTILITIES_SRC_DIR="../../src/utilities";

@test "getMonthAsNum passing in 'Jan'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Jan
  [ "$output" = "01" ]
}

@test "getMonthAsNum passing in 'January'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber January
  [ "$output" = "01" ]
}

@test "getMonthAsNum passing in 'Feb'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Feb
  [ "$output" = "02" ];
}

@test "getMonthAsNum passing in 'February'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber February
  [ "$output" = "02" ];
}

@test "getMonthAsNum passing in 'Mar'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Mar
  [ "$output" = "03" ];
}

@test "getMonthAsNum passing in 'March'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber March
  [ "$output" = "03" ];
}

@test "getMonthAsNum passing in 'Apr'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Apr
  [ "$output" = "04" ];
}

@test "getMonthAsNum passing in 'April'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber April
  [ "$output" = "04" ];
}

@test "getMonthAsNum passing in 'May'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber May
  [ "$output" = "05" ];
}

@test "getMonthAsNum passing in 'Jun'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Jun
  [ "$output" = "06" ];
}

@test "getMonthAsNum passing in 'June'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber June
  [ "$output" = "06" ];
}

@test "getMonthAsNum passing in 'Jul'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Jul
  [ "$output" = "07" ];
}

@test "getMonthAsNum passing in 'July'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber July
  [ "$output" = "07" ];
}

@test "getMonthAsNum passing in 'Aug'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Aug
  [ "$output" = "08" ];
}

@test "getMonthAsNum passing in 'August'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber August
  [ "$output" = "08" ];
}

@test "getMonthAsNum passing in 'Sep'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Sep
  [ "$output" = "09" ];
}

@test "getMonthAsNum passing in 'September'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber September
  [ "$output" = "09" ];
}

@test "getMonthAsNum passing in 'Oct'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Oct
  [ "$output" = "10" ];
}

@test "getMonthAsNum passing in 'October'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber October
  [ "$output" = "10" ];
}

@test "getMonthAsNum passing in 'Nov'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Nov
  [ "$output" = "11" ];
}

@test "getMonthAsNum passing in 'November'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber November
  [ "$output" = "11" ];
}

@test "getMonthAsNum passing in 'Dec'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber Dec
  [ "$output" = "12" ];
}

@test "getMonthAsNum passing in 'December'" {
  run "${UTILITIES_SRC_DIR}"/getMonthAsNumber December
  [ "$output" = "12" ];
}

# @test "addition using dc" {
  # result="$(echo 2 2+p | dc)"
  # [ "$result" -eq 4 ]
# }
