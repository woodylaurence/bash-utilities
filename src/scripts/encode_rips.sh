#!/bin/bash

#Constants
DEFAULT_OUTPUT_DIR="/mnt/Media2/Dump/HandbrakeCLI_Output"

#Error Codes:
ILLEGAL_OPTION=1
ILLEGAL_PRESET=2
ILLEGAL_SPEED=3
ILLEGAL_SUBTITLE=4
ILLEGAL_WAIT=5
ILLEGAL_WORKING_DIR=6

#Read and assign script arguments
while getopts ":p:r:s:i:o:w:" opt
do
	case $opt in
		p )
			case "$OPTARG" in
				br-high)
					rfRating=18
					speed=medium
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 320,640 -R auto,auto -6 dpl2,6ch" ;;

				br-std)
					rfRating=20
					speed=fast
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 320,576 -R auto,auto -6 dpl2,6ch" ;;

				br-small)
					rfRating=22
					speed=medium
					container=mkv
					extension=mkv
					audioSettings="-a 1,1 -E faac,ac3 -B 256,448 -R auto,auto -6 dpl2,6ch" ;;

				br-fast)
					rfRating=20
					speed=veryfast
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

				dvd-small)
					rfRating=22
					speed=medium
					container=mp4
					extension=m4v
					audioSettings="-a 1 -E faac -B 256 -R auto -6 dpl2" ;;

				dvd-fast)
					rfRating=20
					speed=veryfast
					container=mp4
					extension=m4v
					audioSettings="-a 1 -E faac -B 256 -R auto -6 dpl2" ;;

				*)
					echo "ERROR: Illegal preset value '$OPTARG'....Exiting"
					exit $ILLEGAL_PRESET ;;
			esac ;;

		r )
			case "$OPTARG" in
				placebo\
				|veryslow\
				|slower\
				|slow\
				|medium\
				|fast\
				|faster\
				|veryfast\
				|superfast\
				|ultrafast)
					speed="$OPTARG";;

				*)
					echo "ERROR: Illegal speed value '$OPTARG'....Exiting"
					exit $ILLEGAL_SPEED
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
				numEpisodesBetweenSleep=$(sed -r "s*${WAIT_REGEX}*\1*" <<< "$OPTARG")
				secsToSleep=$(sed -r "s*${WAIT_REGEX}*\2*" <<< "$OPTARG")
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
: "${container:=mp4}"
: "${extension:=m4v}"
: "${audioSettings:=-a 1 -E faac -B 320 -R auto -6 dpl2}"
: "${subtitleSettings:=-s scan --subtitle-forced --subtitle-burned}"
: "${sleepingEnabled:=false}"
: "${numEpisodesBetweenSleep:=0}"
: "${secsToSleep:=0}"

#Create output directory if it doesn't exist
outputDirAbsolutePath=$(readlink -m "$workingDir")
if [[ ! -e "$outputDirAbsolutePath" ]]; then
	mkdir "$outputDirAbsolutePath"
fi

echo "Working in $workingDir"
echo "Outputting to $outputDir"
echo "rfRating = $rfRating, speed = $speed"
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
	echo "\nEncoding $file ... "

	filenameWithoutExtension="${file%.*}"

	echo "Encoding $file ...\n"

	#HandBrakeCLI -i "$file" \
	#			 -o "$outputDir/$filenameWithoutExtension.$extension" \
	#			 -f "$container" \
	#			 -m \
	#			 -e x264 \
	#			 	--x264-preset "$speed" \
	#			-q "$rfRating" \
	#				--vfr \
	#			"$audioSettings" \
	#			"$subtitleSettings" \
	#			--strict-anamorphic

	echo "\nCompleted $file\n\n------------------------------------\n"

	let filesEncoded++

	if [[ $sleepingEnabled = true &&
		  $filesEncoded -ne $totalNumFilesToEncode &&
		  $(($filesEncoded % $numEpisodesBetweenSleep)) -eq 0 ]]; then
		echo "Sleeping for ${secsToSleep}s..."
		sleep "$secsToSleep"
	fi
done
