#!/bin/bash

INPUT_FILE="$1"
FIRST_SUB_INDEX_OFFSET=$(( $(ffprobe -v quiet -select_streams s:0 -show_entries stream=index -of csv "$INPUT_FILE" | grep -m1 "stream" | cut -d',' -f2) - 1 ))
SUBTITLE_ENTRIES_FILE=".subtitle_entries.tmp"

echo "Analysing subtitle tracks..."
ffprobe -v quiet -select_streams s -show_entries packet=stream_index,pts_time,duration_time -of csv "$INPUT_FILE" | awk -F',' '$4 > 0.1' > $SUBTITLE_ENTRIES_FILE

subtitle_track_info_table=$(cat "$SUBTITLE_ENTRIES_FILE" | awk -F',' \
                                                               -v first_index_offset="$FIRST_SUB_INDEX_OFFSET" '{count[$2]++} END {
                                                                    print "SubtitleTrack", "StreamIndex", "NumEntries"
                                                                    print "-------------", "-----------", "----------"
                                                                    print first
                                                                    for (stream in count) print "s"(stream-first_index_offset), stream, count[stream]
                                                                  }' \
                                                         | sort -k3 -n | column -t)

echo "$subtitle_track_info_table"
echo ""

while read -p "Please enter subtitle track number to get details for, or 'exit' to stop: " track_num && [ "$track_num" != "exit" ]; do
  stream_index=$((FIRST_SUB_INDEX_OFFSET + track_num))

  echo "Timestamps for track $track_num:"
  echo "--------------------------------"
  cat $SUBTITLE_ENTRIES_FILE | awk -F',' \
                                   -v stream="$stream_index" '$2 == stream {
                                      t = int($3)
                                      h = int(t/3600)
                                      m = int((t%3600)/60)
                                      s = t%60
                                      printf "%02d:%02d:%02d\n", h, m, s
                                    }'
  echo ""
  echo "$subtitle_track_info_table"
done

read -p "Please provide regular subtitle tracks to keep, comma-separated (e.g. 4,5): " regular_subtitle_tracks
read -p "Please provide foreign dialogue subtitle track to keep: " foreign_dialogue_track

mkvpropedit "$INPUT_FILE" --edit track:s"$foreign_dialogue_track" --set name="Foreign Dialogue Only" --set flag-forced=1

subtitle_tracks_to_keep=$(echo "$regular_subtitle_tracks,$foreign_dialogue_track" | tr ',' '\n' | awk -v offset="$FIRST_SUB_INDEX_OFFSET" '{print $1 + offset}' | tr '\n' ',' | sed 's/,$//')
mkvmerge -o "${INPUT_FILE%.*}_muxed.${INPUT_FILE##*.}" --subtitle-tracks "$subtitle_tracks_to_keep" "$INPUT_FILE"

trap "rm -f $SUBTITLE_ENTRIES_FILE" EXIT