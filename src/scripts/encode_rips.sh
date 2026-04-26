#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
DEFAULT_OUTPUT_DIR="/mnt/dump_extra/HandbrakeOutput"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -i | --input-dir)
      input_dir="$2"
      shift 2
      ;;
    -o | --output-dir)
      output_dir="$2"
      shift 2
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    --dvd)
      is_dvd_source=true
      shift
      echo "Haven't dealt with DVD sources yet" >&2
      exit 1
      ;;
    --dark-scenes)
      dark_scenes=true
      shift
      ;;
    --cartoon)
      cartoon=true
      shift
      ;;
    --grainy)
      is_grainy=true
      shift
      ;;
    -q | --quality)
      quality="$2"
      shift 2
      ;;
    --crf)
      custom_crf="$2"
      shift 2
      ;;
    -w | --wait)
      wait_time="$2"
      shift 2
      ;;
    -v  | --verbose)
      verbose_mode=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

A wrapper for HandbrakeCLI to batch encode video files with x265.

Options:
  -i, --input-dir DIR       Directory containing source files (default: current directory)
  -o, --output-dir DIR      Directory for encoded files (default: $DEFAULT_OUTPUT_DIR)
  -q, --quality LEVEL       Quality preset: low, medium (default), high, extra-high
  --crf VALUE               Manually set a CRF value (overrides --quality)
  -w, --wait SECONDS        Time to sleep between encodes (default: 0)

Scenario Flags:
  --dark-scenes             Optimizes for dark content (uses aq-mode 3 to prevent banding)
  --cartoon                 Optimizes for animation (keeps SAO enabled for flat surfaces)
  --grainy                  Preserves film grain for older movies (sets psy-rd=1.5, aq-mode=2)
  --dvd                     Adjusts settings for DVD sources (anamorphic, lower audio bitrate)

Other:
  -h, --help                Show this help message and exit
  -v, --verbose             Print debug statements

Recommended Settings by Film Type:

  1. Modern Digital (Clean, sharp, no grain)
     Examples: The Avengers, John Wick, Top Gun: Maverick, Chef's Table.
     Command: $(basename "$0") -q high
     (Uses default psy-rd=1.0 to keep detail without bloating file size).

  2. Gritty/Vintage Film (Heavy grain, shot on 35mm)
     Examples: Saving Private Ryan, Seven, Ghostbusters (1984), The Godfather.
     Command: $(basename "$0") --grainy -q extra-high
     (Higher psy-rd preserves grain; higher quality prevents grain from "smearing").

  3. Sci-Fi / Space / Horror (Deep blacks, high contrast)
     Examples: Alien, Interstellar, The Dark Knight, Sunshine.
     Command: $(basename "$0") --dark-scenes --grainy
     (AQ-mode 3 is vital here to stop the "void" of space from looking pixelated).

  4. Animation / Anime (Flat surfaces, bold outlines)
     Examples: Spider-Verse, Toy Story, Princess Mononoke, Archer.
     Command: $(basename "$0") --cartoon -q medium
     (Keeps SAO on to ensure large areas of flat color stay perfectly smooth).

  5. Handheld / High Motion (Fast movement, jittery cameras)
     Examples: The Bourne Supremacy, Cloverfield, 1917.
     Command: $(basename "$0") -q high
     (Avoids "low" quality as high motion eats bitrate quickly).

EOF
}

get_crf_rating() {
  if [[ -v custom_crf ]]; then
    echo "$custom_crf"
  else
    case "$quality" in
      low) echo 23 ;;
      medium) echo 22 ;;
      high) echo 20 ;;
      extra-high) echo 19 ;;
      *) echo 22 ;;
    esac
  fi
}

get_extra_encopts_arguments() {
  extra_encopts=$(if [[ -v cartoon || $crf_rating -ge 24 ]]; then echo ""; else echo "no-sao:"; fi)
  if [[ -v is_grainy ]]; then
    extra_encopts+="psy-rd=1.5:psy-rdoq=2.0"
  elif [[ -v cartoon ]]; then
    extra_encopts+="psy-rd=0.5:psy-rdoq=0.5"
  else
    extra_encopts+="psy-rd=1.0:psy-rdoq=1.0"
  fi

  echo "$extra_encopts"
}

get_subtitle_tracks() {
  forced_subtitle_stream_index=$(ffprobe -v quiet -select_streams s -show_entries stream=index:stream_disposition=forced -of csv "$1" | awk -F',' '$3 == 1 {print $2}')

  if [[ -z "$forced_subtitle_stream_index" ]]; then
    echo "1"
  else
    first_sub_stream_index_offset=$(( $(ffprobe -v quiet -select_streams s:0 -show_entries stream=index -of csv "$1" | grep -m1 "stream" | cut -d',' -f2) - 1 ))
    forced_subtitle_stream=$(( $forced_subtitle_stream_index - $first_sub_stream_index_offset))
    echo "1,$forced_subtitle_stream"
  fi
}

run_and_log() {
  if [[ -v verbose_mode ]]; then
    printf '[DEBUG]'
    printf ' %q' "$@"
    echo
  fi
  "$@"
}

main() {
  parse_args "$@"

  input_dir=${input_dir:-"$PWD"}
  output_dir=${output_dir:-"$DEFAULT_OUTPUT_DIR"}
  quality=${quality:-"medium"}
  aq_mode=$(if [[ -v dark_scenes ]]; then echo 3; else echo 2; fi)
  crf_rating=$(get_crf_rating)
  audio_bitrate=$(if [[ -v is_dvd_source ]]; then echo 160; else echo 192; fi)
  anamorphic_setting=$(if [[ -v is_dvd_source ]]; then echo "--auto-anamorphic"; else echo "--non-anamorphic"; fi)
  extra_encopts_arguments=$(get_extra_encopts_arguments)
  wait_time=${wait_time:-0}

  #Ensure output directory exists
  output_dir_absolute_path=$(realpath "$output_dir")
  mkdir -p "$output_dir_absolute_path"

  log_file="$output_dir/HandbrakeOutput.log"

  shopt -s nullglob
  for file in "$input_dir"/*.{mkv,m4v,mp4}; do
    subtitle_tracks=$(get_subtitle_tracks "$file")

    filename=$(basename "$file")
    output_filename="$output_dir/${filename%.*}.mkv"
    echo -e "\nEncoding $filename ... " 2>&1 | tee -a "$log_file"

    run_and_log HandBrakeCLI \
      --input "$file" --output "$output_filename" \
      --format mkv \
      --markers \
      --encoder x265_10bit --encoder-preset slow --quality "$crf_rating" \
      --encopts="strong-intra-smoothing=0:rect=0:rskip=2:aq-mode=${aq_mode}:${extra_encopts_arguments}" \
      --vfr \
      ${anamorphic_setting} \
      --audio 1 --aencoder av_aac --ab ${audio_bitrate} --mixdown dpl2 \
      --subtitle "$subtitle_tracks" \
      2>>"$log_file"

    if [[ "$subtitle_tracks" =~ ,([0-9])$ ]]; then
      mkvpropedit "$output_filename" --edit track:s${BASH_REMATCH[1]} --set name="Foreign Dialogue Only" --set flag-forced=1 > /dev/null || echo "Failed to set forced subtitle tack on output file."
    fi

    echo -e "\nCompleted $filename\n\n------------------------------------\n" | tee -a "$log_file"

    if [[ $wait_time -gt 0 ]]; then
      echo "Sleeping for ${wait_time}s..."
      sleep $wait_time
    fi
  done
}

main "$@"