#!/bin/bash
set -euo pipefail
shopt -s nullglob

declare -r ORIGINAL_MEDIA_DIR="$PWD/original-media"
declare -r UNMATCHED_MEDIA_DIR="$PWD/unmatched-media"
declare -r RENAMED_MEDIA_DIR="$PWD/renamed-media"
declare unmatched_media_outputs=()
declare matched_media_outputs=()
declare previous_series_search_term=""

__check_media_files_exist_in_directory() {
  if [[ -z "$(find . -mindepth 1 -maxdepth 1 -name '*.mkv' -print -quit)" ]]; then
    echo "ERROR - No media files found in current directory." >&2
    exit 1
  fi
}

__get_media_files_tv_info_json() {
  local media_files_tv_info=()
  for media_file in *.mkv; do
    [[ ! $media_file =~ S[0-9]+E[0-9]+ ]] && continue

    media_files_tv_info+=("$(get-tv-info-from-filename "$media_file")")
  done

  local media_files_tv_info_as_json=$(printf '%s\n' "${media_files_tv_info[@]}")
  local tv_series_to_search_for=()
  mapfile -t tv_series_to_search_for < <(jq -s -r 'map(.formattedSeriesName | ascii_downcase) | unique | .[]' <<< "$media_files_tv_info_as_json")

  local -A series_name_info_lookup=()
  for series_name in "${tv_series_to_search_for[@]}"; do
    series_name_info_lookup["$series_name"]="$(__get_confirmed_tv_series_details "$series_name")"
  done

  for index in "${!media_files_tv_info[@]}"; do
    local series_name_lookup_key=$(jq -r '.formattedSeriesName | ascii_downcase' <<< "${media_files_tv_info[$index]}")
    local tvdb_info_for_series="${series_name_info_lookup[$series_name_lookup_key]}"
    media_files_tv_info[$index]=$(jq -c -n \
                                     --argjson json "${media_files_tv_info[$index]}" \
                                     --argjson tvdb_info_json "$tvdb_info_for_series" \
                                     '$json + { seriesId: $tvdb_info_json.id, seriesReleaseYear: $tvdb_info_json.release_year }')

  done

  printf '%s\n' "${media_files_tv_info[@]}" | jq -s '.'
}

__setup_directories() {
  local media_files_tv_info_json="$1"
  local directories=("$ORIGINAL_MEDIA_DIR" "$UNMATCHED_MEDIA_DIR" "$RENAMED_MEDIA_DIR")

  for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    if [[ -n "$(find "$dir" -mindepth 1 -print -quit)" ]]; then
      echo "ERROR - $dir is not empty."
      exit 1
    fi
  done

  local filenames=()
  mapfile -t filenames < <(jq -r '.[].filename' <<< "$media_files_tv_info_json")
  for file in "${filenames[@]}"; do
    ln "$file" "$ORIGINAL_MEDIA_DIR/$file"
  done
}

__get_confirmed_tv_series_details() {
  local series_name="$1"
  local tvdb_search_results trimmed_tvdb_search_results fzf_input selected_option selected_id tv_series_details

  tvdb_search_results=$(tvdb-search-series "$series_name")
  trimmed_tvdb_search_results=$(jq -c '(.[:5]) // []' <<< "$tvdb_search_results")
  jq -r '.' <<< "$trimmed_tvdb_search_results" >&2
  echo >&2

  fzf_input=$(jq -r '.[] | "\(.id) - \(.name) (\(.release_year))"' <<< "$trimmed_tvdb_search_results")
  fzf_input+=$'\nNone of the above'
  selected_option=$(fzf --height 10% --prompt="Matching '${series_name}', please select option: " --layout=reverse <<< "$fzf_input")

  if [[ "$selected_option" != "None of the above" ]]; then
    selected_id=$(sed -E "s/([0-9]+) - .*/\1/"  <<< "$selected_option")
    jq --arg id "$selected_id" '.[] | select(.id == $id)' <<< "$trimmed_tvdb_search_results"
  else
    echo "null"
  fi
}

__try_match_media_file() {
  local media_file_tv_info="$1"

  IFS=$'\t' read -r series_search_term series_id season_number episode_number < <(jq -r '[.seriesSearchTerm, .seriesId, .seasonNumber, .episodeNumber] | @tsv' <<< "$media_file_tv_info")

  if [[ "$series_id" == "null" ]]; then
    __handle_unmatched_episode "$media_file_tv_info"
    return
  fi

  episode_metadata=$(tvdb-get-series-episode-details $series_id $season_number $episode_number)
  if [[ "$episode_metadata" == "null" ]]; then
    __handle_unmatched_episode "$media_file_tv_info"
  else
    if [[ "$previous_series_search_term" != "" && "$series_search_term" != "$previous_series_search_term" ]]; then
      matched_media_outputs+=("")
    fi

    previous_series_search_term="$series_search_term"
    __handle_matched_episode "$media_file_tv_info" "$episode_metadata"
  fi
}

__handle_unmatched_episode() {
  local media_file_tv_info="$1"

  IFS=$'\t' read -r original_filename series_search_term < <(jq -r '[.filename, .seriesSearchTerm] | @tsv' <<< "$media_file_tv_info")
  mv "$original_filename" "$UNMATCHED_MEDIA_DIR/$original_filename"
  unmatched_media_outputs+=(" - $original_filename (series search term - '$series_search_term')")
}

__handle_matched_episode() {
  local media_file_tv_info="$1"
  local episode_metadata="$2"

  extracted_json_info=$(jq -r '[.filename, .formattedSeriesName, .seriesReleaseYear, .seasonNumber, .formattedSeasonNum, .episodeNumber, .formattedEpisodeNum, .extension] | @tsv' <<< "$media_file_tv_info")
  IFS=$'\t' read -r original_filename series_name release_year season_number formatted_season_number episode_number formatted_episode_number extension <<< "$extracted_json_info"
  episode_name=$(jq -r '.name' <<< "$episode_metadata")

  season_folder="$RENAMED_MEDIA_DIR/$series_name ($release_year)/Season $season_number"
  mkdir -p "$season_folder"

  new_filename="$series_name ($release_year) S${formatted_season_number}E${formatted_episode_number} - $episode_name.$extension"
  mv "$original_filename" "$season_folder/$new_filename"

  matched_media_outputs+=(" - $original_filename --> $new_filename ($series_name/Season $season_number)")
}

__print_renaming_output() {
  if [[ ${#unmatched_media_outputs[@]} -gt 0 ]]; then
    echo -e "\n\n"
    echo "Unable to rename the following files:"
    printf '%s\n' "${unmatched_media_outputs[@]}"
    echo -e "--------------------------------------------\n\n"
  fi

  if [[ ${#matched_media_outputs[@]} -gt 0 ]]; then
    echo -e "\n\n"
    echo "Renamed the following files:"
    printf '%s\n' "${matched_media_outputs[@]}"
    echo -e "--------------------------------------------\n\n"
  fi
}

__cleanup_directories() {
  if [[ -z "$(find "$UNMATCHED_MEDIA_DIR" "$RENAMED_MEDIA_DIR" -mindepth 1 -print -quit)" ]]; then
    rmdir "$ORIGINAL_MEDIA_DIR" 2>/dev/null
    rmdir "$RENAMED_MEDIA_DIR" 2>/dev/null
    rmdir "$UNMATCHED_MEDIA_DIR" 2>/dev/null
  fi
}

main() {
  __check_media_files_exist_in_directory
  media_files_tv_info_json=$(__get_media_files_tv_info_json)
  __setup_directories "$media_files_tv_info_json"

  mapfile -t ordered_media_files_tv_infos_json < <(jq -c 'sort_by((.formattedSeriesName | ascii_downcase), .seasonNumber, .episodeNumber) | .[]' <<< "$media_files_tv_info_json")
  for media_file_tv_info in "${ordered_media_files_tv_infos_json[@]}"; do
    __try_match_media_file "$media_file_tv_info"
  done

  __print_renaming_output
}

trap __cleanup_directories EXIT
main