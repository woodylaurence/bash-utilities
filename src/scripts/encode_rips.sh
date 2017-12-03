#!/bin/bash

#Constants
DEFAULT_OUTPUT_DIR="/mnt/Dump/HandbrakeCLI_Output"

#Error Codes:
ILLEGAL_OPTION=1
ILLEGAL_PRESET=2
ILLEGAL_ENCODER=3
ILLEGAL_SUBTITLE=4
ILLEGAL_WAIT=5
ILLEGAL_WORKING_DIR=6

#Read and assign script arguments
while getopts ":p:e:s:i:o:w:" opt
do
	case $opt in
		p )
			case "$OPTARG" in
				br-high)
					rfRating=18
					speed=medium
					encoder=x264
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 320,640 -R auto,auto -6 dpl2,6ch" ;;

				br-std)
					rfRating=20
					speed=fast
					encoder=x264
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 320,576 -R auto,auto -6 dpl2,6ch" ;;

				br-fast)
					rfRating=20
					speed=veryfast
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 320,576 -R auto,auto -6 dpl2,6ch" ;;

				br-hevc)
					rfRating=20
					speed=medium
					encoder=x265
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 320,576 -R auto,auto -6 dpl2,6ch" ;;

				dvd-high)
					rfRating=19
					speed=medium
					container=mp4
					extension=m4v
					audioSettings="-a 1 -E faac -B 320 -R auto -6 dpl2" ;;

				dvd-std)
					rfRating=20
					speed=fast
					container=mp4
					extension=m4v
					audioSettings="-a 1 -E faac -B 256 -R auto -6 dpl2" ;;

				dvd-fast)
					rfRating=20
					speed=veryfast
					container=mp4
					extension=m4v
					audioSettings="-a 1 -E faac -B 256 -R auto -6 dpl2" ;;

				dvd-hevc)
					rfRating=20
					speed=medium
					encoder=x265
					container=mp4
					extension=m4v
					audioSettings="-a 1 -E faac -B 256 -R auto -6 dpl2" ;;

				*)
					echo "ERROR: Illegal preset value '$OPTARG'....Exiting"
					exit $ILLEGAL_PRESET ;;
			esac ;;

		e )
			case "$OPTARG" in
				x264)
					encoder=x264 ;;

				x265)
					encoder=x265 ;;

				*)
					echo "ERROR: Illegal encoder value '$OPTARG'....Exiting"
					exit $ILLEGAL_ENCODER
			esac ;;

		s )
			case "$OPTARG" in
				force-burn)
					subtitleSettings="-s scan --subtitle-forced --subtitle-burned" ;;

				force)
					subtitleSettings="-s scan --subtitle-forced --subtitle-default" ;;

				burn)
					subtitleSettings="-s 1 --subtitle-burned" ;;

				std)
					subtitleSettings="-s 1" ;;

				none)
					subtitleSettings="" ;;

				*)
					echo "ERROR: Illegal subtitle value '$OPTARG'....Exiting"
					exit $ILLEGAL_SUBTITLE
				esac ;;
		i )
			if [[ ! -e "$OPTARG" ]]; then
				workingDir="$OPTARG"
			else
				echo "ERROR: Working directory '$OPTARG' doesn't exist....Exiting"
				exit $ILLEGAL_WORKING_DIR
			fi ;;

		o )
			outputDir="$OPTARG" ;;

		w )
			WAIT_REGEX="^([0-9]+)x([0-9]+)$"
			if [[ "$OPTARG" =~ $WAIT_REGEX ]]; then
				numEpisodesBetweenSleep=$(sed -nr "s/${WAIT_REGEX}/\1/p" <<< "$OPTARG")
				secsToSleep=$(sed -nr "s/${WAIT_REGEX}/\2/p" <<< "$OPTARG")
				sleepingEnabled=true
			else
				echo "ERROR: Illegal wait option '$OPTARG'."
				echo "Wait option follows form: $WAIT_REGEX , i.e. 3x60....Exiting"
				exit $ILLEGAL_WAIT
			fi ;;

		* )
			echo "ERROR: Illegal optoin '$opt'....Exiting"
			exit $ILLEGAL_OPTION ;;
		esac
done

#Assign variables if not already set
: "${workingDir:=$PWD}"
: "${outputDir:=$DEFAULT_OUTPUT_DIR}"
: "${rfRating:=20}"
: "${speed:=fast}"
: "${encoder:=x264}"
: "${container:=mp4}"
: "${extension:=m4v}"
: "${audioSettings:=-a 1 -E faac -B 320 -R auto -6 dpl2}"
: "${subtitleSettings:=-s scan --subtitle-forced --subtitle-burned}"
: "${sleepingEnabled:=false}"
: "${numEpisodesBetweenSleep:=0}"
: "${secsToSleep:=0}"

#Create output directory if it doesn't exist
outputDirAbsolutePath=$(readlink -m "$outputDir")
if [[ ! -e "$outputDirAbsolutePath" ]]; then
	mkdir "$outputDirAbsolutePath"
fi

outputFile="$outputDir/HandbrakeOutput.txt"

echo "Working in $workingDir"
echo "Outputting to $outputDir"
echo "rfRating = $rfRating, speed = $speed, encoder = $encoder"
echo "container = $container, extension = $extension"
echo "audioSettings = $audioSettings"
echo "subtitleSettings = $subtitleSettings"
echo "Sleeping ${secsToSleep}s every $numEpisodesBetweenSleep episodes"

cd "$workingDir"

filesEncoded=0
#TODO Relax the restriction on only processing .mkv files
totalNumFilesToEncode=$(ls -1 *.mkv | wc -l)
for file in *.mkv
do
	echo "\nEncoding $file ... " 2>&1 tee -a "$outputFile"

	filenameWithoutExtension="${file%.*}"

	HandBrakeCLI -i "$file" \
				 -o "$outputDir/$filenameWithoutExtension.$extension" \
				 -f "$container" \
				 -m \
				 -e $encoder \
				 	--${encoder}-preset "$speed" \
				 -q "$rfRating" \
					--vfr \
				 "$audioSettings" \
				 "$subtitleSettings" \
				 --auto-anamorphic 2>> "$outputFile"

	echo "\nCompleted $file\n\n------------------------------------\n"

	let filesEncoded++

	if [[ $sleepingEnabled = true &&
		  $filesEncoded -ne $totalNumFilesToEncode &&
		  $(($filesEncoded % $numEpisodesBetweenSleep)) -eq 0 ]]; then
		echo "Sleeping for ${secsToSleep}s..."
		sleep "$secsToSleep"
	fi
done
