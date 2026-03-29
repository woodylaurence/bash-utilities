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
  --is_grainy                  Preserves film grain for older movies (sets psy-rd=1.5, aq-mode=2)
  --dvd                     Adjusts settings for DVD sources (anamorphic, lower audio bitrate)

Other:
  -h, --help                Show this help message and exit

Examples:
  $(basename "$0") -i ./rips -o ./encoded --quality high
  $(basename "$0") --dark-scenes --crf 18 -w 60
EOF
}

get_crf_rating() {
  if [[ -v custom_crf ]]; then
    echo "$custom_crf"
  else
    case "$quality" in
      low)
        echo 23
        ;;
      medium)
        echo 21
        ;;
      high)
        echo 20
        ;;
      extra-high)
        echo 19
        ;;
      *)
        echo 21
        ;;
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

  #deal with subtitles, what do we want to do here? We want to scan subtitle 1 as standard, but we need to decide what to do if there's some foreign dialogue
  #need to be able to determine whether a source file has a separate foreign subtitle track, or it has a single substitle track with forced parts of it
  #claude suggests that the --subtitle-forced flag would only output the subtitle track if it had forced flag on the source, could be useful

  #Ensure output directory exists
  output_dir_absolute_path=$(realpath "$output_dir")
  mkdir -p "$output_dir_absolute_path"

  log_file="$output_dir/HandbrakeOutput.log"

  shopt -s nullglob
  for file in "$input_dir"/*.{mkv,m4v,mp4}; do
    filename=$(basename "$file")
    echo -e "\nEncoding $filename ... " 2>&1 | tee -a "$log_file"

    HandBrakeCLI \
      --input "$file" --output "$output_dir/${filename%.*}.mkv" \
      --format mkv \
      --markers \
      --encoder x265_10bit --encoder-preset slow --quality "$crf_rating" \
      --encopts="strong-intra-smoothing=0:rect=0:rskip=2:aq-mode=${aq_mode}${extra_encopts_arguments}" \
      --vfr \
      ${anamorphic_setting} \
      --audio 1 --aencoder av_aac --ab ${audio_bitrate} --mixdown dpl2 \
      --subtitle 1 \
      2>>"$log_file"

    echo -e "\nCompleted $filename\n\n------------------------------------\n" | tee -a "$log_file"

    if [[ $wait_time -gt 0 ]]; then
      echo "Sleeping for ${wait_time}s..."
      sleep $wait_time
    fi
  done
}

main "$@"