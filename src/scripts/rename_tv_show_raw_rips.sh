#!/bin/bash

WORK_DIR="/mnt/dump/RawRips/TV Shows"
RENAMED_MARKER_FILE_NAME=".renamed"

shopt -s nullglob

for series_path in "$WORK_DIR"/*; do
  series_name=$(basename "$series_path")

  [[ -d "$series_path" ]] || continue

  if [[ ! $series_name =~ ^[a-zA-Z0-9]+$ ]]; then
    echo "Warning - can't parse series name from $series_name. Skipping..."
    continue
  fi

  echo "Looking at $series_name"

  for season_path in "$series_path"/*; do
    season_folder=$(basename "$season_path")

    [[ -d "$season_path" ]] || continue

    if [[ -e "$season_path/$RENAMED_MARKER_FILE_NAME" ]]; then
      echo "Already renamed file in $series_name/$season_folder"
      continue
    fi

    if [[ $season_folder =~ ^Season([0-9]+)$ ]]; then
      season_number=${BASH_REMATCH[1]}
    else
      echo "Warning - Could not parse season number for $series_name / $season_folder"
      continue
    fi

    formatted_season_number=$(printf %02d "$season_number")

    mkdir -p "$season_path/MakeMKVOutput"

    i=1

    for disc_path in "$season_path"/Disc[0-9]*/; do
      disc_folder=$(basename "$disc_path")

      for episode_file in "$disc_path"/*.mkv; do
        episode_base=$(basename "$episode_file")
        formatted_episode_number=$(printf %02d "$i")

        target="$season_path/${series_name}_S${formatted_season_number}E${formatted_episode_number}.mkv"

        echo "Linking $season_folder/$disc_folder/$episode_base --> $(basename "$target")"

        ln "$episode_file" "$target"

        ((i++))
      done

      mv "$disc_path" "$season_path/MakeMKVOutput/"
    done

    touch "$season_path/$RENAMED_MARKER_FILE_NAME"
    echo "Renamed episodes in $season_folder"
  done

  echo
  echo
done
