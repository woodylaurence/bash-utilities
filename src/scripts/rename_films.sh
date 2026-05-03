#!/bin/bash
set -euo pipefail

declare -r ORIGINAL_MEDIA_DIR="$PWD/original-media"
declare -r UNMATCHED_MEDIA_DIR="$PWD/unmatched-media"
declare -r RENAMED_MEDIA_DIR="$PWD/renamed-media"

__setup_directories() {
  local directories=("$ORIGINAL_MEDIA_DIR" "$UNMATCHED_MEDIA_DIR" "$RENAMED_MEDIA_DIR")

  for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    if [[ -n $(ls -A "$dir") ]]; then
      echo "ERROR - $dir is not empty."
      exit 1
    fi
  done
}

__handle_unmatched_film() {
  local file="$1"

  mv "$file" "$UNMATCHED_MEDIA_DIR/$file"
  unmatched_files+=("$file")
}

__handle_matched_film() {
  local file="$1"
  local tmdb_search_result="$2"
  local film_name film_release_year full_film_name

  film_name=$(jq -r '.title' <<< "$tmdb_search_result" | sed "s/: / - /g")
  film_release_year=$(jq -r '.release_date | split("-")[0]' <<< "$tmdb_search_result")
  full_film_name="${film_name} (${film_release_year})"

  mkdir -p "$RENAMED_MEDIA_DIR/$full_film_name"
  mv "$file" "$RENAMED_MEDIA_DIR/$full_film_name/${full_film_name}.mkv"
  matched_files+=("$file -> $full_film_name")
}

__get_confirmed_film_details() {
  local tmdb_search_results="$1"
  local trimmed_tmdb_search_results fzf_input selected_option selected_id film_details

  trimmed_tmdb_search_results=$(jq -r '.[:5]' <<< "$tmdb_search_results")
  jq -r '.' <<< "$trimmed_tmdb_search_results" > /dev/tty
  echo > /dev/tty

  fzf_input=$(jq -r '.[] | "\(.id) - \(.title) (\(.release_date | split("-")[0]))"' <<< "$trimmed_tmdb_search_results")
  fzf_input+=$'\nNone of the above'
  selected_option=$(fzf --height 10% --prompt="Matching '${file}', please select option: " --layout=reverse <<< "$fzf_input")

  if [[ "$selected_option" != "None of the above" ]]; then
    selected_id=$(sed -E "s/([0-9]+) - .*/\1/"  <<< "$selected_option")
    film_details=$(jq --arg id "$selected_id" '.[] | select(.id == ($id | tonumber))' <<< "$trimmed_tmdb_search_results")
    echo "$film_details"
  fi
}

__try_find_film_match() {
  local file="$1"

  film_search_name=$(tmdb-get-formatted-search-term-from-filename "$file")
  tmdb_search_results=$(tmdb-search-film "$film_search_name")
  num_results_found=$(jq "length" <<< "$tmdb_search_results")

  case "$num_results_found" in
    0)
      echo "WARNING - Could not find any results for '$film_search_name'" >&2
      __handle_unmatched_film "$file"
      ;;

    *)
      confirmed_film_details=$(__get_confirmed_film_details "$tmdb_search_results")
      if [[ -n "$confirmed_film_details" ]]; then
        __handle_matched_film "$file" "$confirmed_film_details"
      else
        __handle_unmatched_film "$file"
      fi
      ;;

  esac
}

__print_matching_results() {
  clear

  echo "=== Summary ==="
  echo "Renamed (${#matched_files[@]}):"
  for entry in "${matched_files[@]}"; do echo "  ✔ $entry"; done

  echo

  echo "Unmatched (${#unmatched_files[@]}):"
  for entry in "${unmatched_files[@]}"; do echo "  ✘ $entry"; done
}

main() {
  matched_files=()
  unmatched_files=()

  shopt -s nullglob
  film_media_files=(*.mkv)

  if [[ ${#film_media_files[@]} -eq 0 ]]; then
    echo "ERROR - No media files found in current directory." >&2
    exit 1
  fi

  __setup_directories

  for file in "${film_media_files[@]}"; do
    clear
    ln "$file" "$ORIGINAL_MEDIA_DIR/$file"

    __try_find_film_match "$file"
  done

  __print_matching_results
}

main