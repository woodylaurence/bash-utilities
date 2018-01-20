#!/bin/bash

# Directories
ORIGINAL_MEDIA_DIR="$PWD/original-media"
UNMATCHED_MEDIA_DIR="$PWD/unmatched-media"
RENAMED_MEDIA_DIR="$PWD/renamed-media"
TEMP_METADATA_DIR="$PWD/temp-metadata"

#### Start in directory with media files; could be named in numerous ways
shopt -s nullglob
allMediaFiles=(*.mkv)

if [[ ${#allMediaFiles[@]} -eq 0 ]]; then
	echo "No media files found in current directory."
	exit
fi

#Make Directories
mkdir -p "$ORIGINAL_MEDIA_DIR"
mkdir -p "$UNMATCHED_MEDIA_DIR"
mkdir -p "$RENAMED_MEDIA_DIR"

#### Copy (link to save time) these files to a staging area and rename to standard format
for file in "${allMediaFiles[@]}"
do
	ln "$file" "$ORIGINAL_MEDIA_DIR/$file"
done

#### Extract series information for TV Shows

mediaFilesTvInfoJson="["
for file in "${allMediaFiles[@]}"
do
	tvInfoJson=$(get-tv-info-from-filename "$file")
	mediaFilesTvInfoJson="${mediaFilesTvInfoJson}$tvInfoJson,"
done
mediaFilesTvInfoJson=$(echo "$mediaFilesTvInfoJson" | sed -r "s/(.*).$/\1]/")

echo "$mediaFilesTvInfoJson" | jq -r "map(.formattedSeriesName | ascii_downcase ) | unique"



#### Use above information to rename files in staging area.

#### Display renames to user, accept or deny
