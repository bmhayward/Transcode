#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/batchTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch
#	Copyright (c) 2016-2017 Brent Hayward			
#	
#	
#	This script is a wrapper to Don Melton's batch script which transcodes DVD and Blu-Ray content.
#	https://github.com/donmelton/video_transcoding
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp=""	
	local minOS=""
                                                     										# define version number
	versStamp="Version 2.9.6, 04-01-2017"
	minOS="10.11"
																							# verify the minimum supported OS
	# . "_versionCheck.sh" "${minOS}"
	
	readonly SCRIPTVERS="${versStamp:8:${#versStamp}-20}"
	                                                            							# define script name
	readonly SCRIPTNAME=$(basename "${0%%.*}")
																							# get the paths
	local DIR=""
	local SOURCE="${BASH_SOURCE[0]}"
	
	while [[ -h "${SOURCE}" ]]; do 															# resolve ${SOURCE} until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
		SOURCE="$(readlink "${SOURCE}")"
		[[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" 									# if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	
	loggerTag="batch.command"
	
	readonly LIBDIR="${HOME}/Library"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# get the path to the Transcode folder, returns the WORKDIR and CONVERTDIR variable

	readonly CROPSDIR="${LIBDIR}/Application Support/Transcode/Crops"
	readonly CONVERTDIR="${WORKDIR}/Convert"
	readonly LOGDIR="${WORKDIR}/Logs"
	readonly SUBSDIR="${WORKDIR}/Subtitles"
	readonly OUTDIR="${WORKDIR}/Completed"
	readonly ORIGINALSDIR="${OUTDIR}/Originals"

	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
	readonly WORKINGPATH="${LIBDIR}/Preferences/com.videotranscode.batch.working.plist"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	
	readonly VERSCURRENT=$(/usr/libexec/PlistBuddy -c 'print :CFBundleShortVersionString' "${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
	
	readonly LIGHTBLUE=$'\033[0;36m'
	readonly LIGHTBLUEBOLD=$'\033[1;36m'
	readonly LIGHTGREEN=$'\033[0;32m'
	readonly LIGHTGREENBOLD=$'\033[1;32m'
	readonly LIGHTYELLOW=$'\033[0;93m'
	readonly LIGHTYELLOWBOLD=$'\033[1;93m'
	readonly LIGHTMAGENTA=$'\033[0;95m'
	readonly LIGHTMAGENTABOLD=$'\033[1;95m'
	readonly WHITEBOLD=$'\033[1;37m'
	readonly RED=$'\033[0;91m'
	readonly REDBOLD=$'\033[1;91m'
	readonly UNDERLINE=$'\033[4m'
	readonly NC=$'\033[0m'	# No Color
	readonly NL=$'\033[24m'	# No underline
}

function get_Prefs () {
																							# create the default preferences file if it does not exist
	if [[ ! -e "${PREFPATH}" ]]; then
	   . "_writePrefs.sh" "${PREFPATH}"
	fi
	
	. "_readPrefs.sh" "${PREFPATH}"															# read in the preferences from prefs.plist
}

function build_Resources () {
																							# make sure all the directories are in place and create if not
	if [[ ! -d "${CONVERTDIR}" ]]; then
	  	mkdir -p "${CONVERTDIR}"
	fi	
	
	if [[ ! -d "${OUTDIR}" ]]; then
	  mkdir -p "${OUTDIR}"
	fi
	
	if [[ ! -d "${ORIGINALSDIR}" ]]; then
	  mkdir -p "${ORIGINALSDIR}"
	fi
	
	if [[ ! -d "${CROPSDIR}" ]]; then
	  	mkdir -p "${CROPSDIR}"
	fi
	
	if [[ ! -d "${LOGDIR}" ]]; then
	  mkdir -p "${LOGDIR}"
	fi
	
	if [[ ! -d "${SUBSDIR}" ]]; then
	  mkdir -p "${SUBSDIR}"
	fi
}

function get_VideoQualitySettings () {
	# ${1}: file path
																							# set the output quality listed in the prefs.plist
	local qualitySetting=""
	local forcedSetting=""
	local index=0
	local saveIFS=""
	
	declare -a outputSetting_a
	
	if [[ -z "${outQuality_}" ]];then
																							# using the defaults
		qualitySetting="--default"
	else
																							# strip any white space from outQuality_
		qualitySetting=$(echo "${outQuality_//[[:blank:]]/}")
																							# reconstruct the qualitySetting setting
		saveIFS=${IFS}
		IFS=',' read -r -a outputSetting_a <<< "${qualitySetting}"							# convert string to array based on comma
		IFS=${saveIFS}																		# restore IFS
																							# reconstruct outQuality with dashes
		for index in "${!outputSetting_a[@]}"; do
			if [[ "${index}" == "0" ]]; then
				qualitySetting="--${outputSetting_a[${index}]}"
			else
				qualitySetting="${outQuality},--${outputSetting_a[${index}]}"	
			fi
		done
	fi
	
	if [[ "${1}" == *".--"* ]]; then
																							# additional video quality setting embedded in the filename
		forcedSetting="--${1##*-}"
		
		if [[ "${forcedSetting}" != *"${qualitySetting}"* ]]; then
																							# make sure the forced setting is not already set by the prefs.plist
			qualitySetting="${qualitySetting},${forcedSetting%%.*}"
		fi
	fi
																							# add the quality setting to the array
	videoQuality_a+=("${qualitySetting}")
}

function get_ThisQualitySetting () {
	# ${1}: index of the videoQuality array
	
	local saveIFS=""
																							# clear the array
	unset qualitySettings_a

	saveIFS=${IFS}
	IFS=',' read -r -a qualitySettings_a <<< "${videoQuality_a[${1}]}"						# convert string to array based on comma
	IFS=${saveIFS}																			# restore IFS
}

function get_CropValue () {
	# ${1}: file to check for cropping
	# Returns: crop value
	
	local capturedOutput=""
	local cropValue=""
	local fileNameExt=""
	local fileName=""
	local cropHbValue=""
	local cropffmpegValue=""
	local run_4Screen=""
																							# set to no cropping
	cropValue="0:0:0:0"
	fileNameExt="${1##*/}"																	# filename with extension
	fileName="${fileNameExt%.*}.txt"														# filename without extension
																							# get cropping information
	capturedOutput=$(detect-crop "${1}")
	
	declare -a cropDetected_a
																							# convert string to array based on newline
	saveIFS=${IFS}
	IFS=$'\n' read -rd '' -a cropDetected_a <<<"${capturedOutput}"
	IFS=${saveIFS}
	
	if [[ "${cropDetected_a[0]}" == *"From HandBrakeCLI:"* ]] && [[ "${showCropPreview_}" != "ignore" ]]; then	
		cropHbValue="${cropDetected_a[3]##*--crop}"
		cropHbValue="${cropHbValue%% /*}"
		cropHbValue="${cropHbValue// /}"													# get the crop value in the form of '#:#:#:#', e.g. '0:0:6:2'

		cropffmpegValue="${cropDetected_a[7]##*--crop}"
		cropffmpegValue="${cropffmpegValue%% /*}"
		cropffmpegValue="${cropffmpegValue// /}"											# get the crop value in the form of '#:#:#:#', e.g. '0:0:6:2'
																							# create the shell scripts to be run by the screen command and put them in /tmp
		run_4Screen="/tmp/run_HBCrop.sh"
		touch "${run_4Screen}"
		printf '%s\n' "#!/usr/bin/env bash" >> "${run_4Screen}"
		printf '%s\n' "${cropDetected_a[1]} --keep-open --title=\"Cropped ${cropHbValue}\"" >> "${run_4Screen}"
		printf '%s\n' "exit 0" >> "${run_4Screen}"

		chmod +x "${run_4Screen}"

		run_4Screen="/tmp/run_ffmpegCrop.sh"
		touch "${run_4Screen}"
		printf '%s\n' "#!/usr/bin/env bash" >> "${run_4Screen}"
		printf '%s\n' "${cropDetected_a[5]}  --geometry=100:100 --keep-open --title=\"Cropped ${cropffmpegValue}\"" >> "${run_4Screen}"
		printf '%s\n' "exit 0" >> "${run_4Screen}"

		chmod +x "${run_4Screen}"

		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "${LIGHTYELLOWBOLD}=========================================================================${NC}"
		. "_echoMsg.sh" "Crop Select –"
		. "_echoMsg.sh" "Handbrake ${LIGHTYELLOWBOLD}${cropHbValue}${NC}"
		. "_echoMsg.sh" "ffmpeg ${LIGHTYELLOWBOLD}${cropffmpegValue}${NC}"
		. "_echoMsg.sh" ""

		read -r -p "=> ${LIGHTYELLOWBOLD}[1]${NC} view videos with cropping options, ${LIGHTYELLOWBOLD}[2]${NC} use default cropping ${cropffmpegValue}, ${LIGHTGREENBOLD}[press Return]${NC} to continue without cropping " response
		case ${response} in
			[1] )																			# view video options
				printf '%s\n\n' "${LIGHTYELLOWBOLD}Cropping${NC} will denoted by a ${UNDERLINE}white border${NC} in each video"
				
				sleep 1
																							# open each video in a detached screen
				screen -dm -S HBCrop /tmp/run_HBCrop.sh
				screen -dm -S ffmpegCrop /tmp/run_ffmpegCrop.sh
				
				read -r -p "=> ${LIGHTYELLOWBOLD}[1]${NC} crop using ${cropHbValue}, ${LIGHTYELLOWBOLD}[2]${NC} crop using ${cropffmpegValue}, ${LIGHTGREENBOLD}[press Return]${NC} to continue with no cropping " response
				case ${response} in
					[1] )																	# handbrake
						cropValue="${cropHbValue}"
					;;

					[2] )																	# ffmpeg
						cropValue="${cropffmpegValue}"
					;;
				esac
																							# stop mpv
				pkill mpv	
			;;

			[2] )
				cropValue="${cropffmpegValue}"												# default - use ffmpeg
			;;
		esac
																							# clean up
		rm -f "/tmp/run_HBCrop.sh"
		rm -f "/tmp/run_ffmpegCrop.sh"
	fi
																							# always show crop options
	if [[ "${showCropPreview_}" == "true" ]]; then
		cropffmpegValue="${cropDetected_a[1]##*--crop}"
		cropffmpegValue="${cropffmpegValue%% /*}"
		cropffmpegValue="${cropffmpegValue// /}"											# get the crop value in the form of '#:#:#:#', e.g. '0:0:6:2'
		
		run_4Screen="/tmp/run_ffmpegCrop.sh"
		touch "${run_4Screen}"
		printf '%s\n' "#!/usr/bin/env bash" >> "${run_4Screen}"
		printf '%s\n' "${cropDetected_a[5]}  --geometry=100:100 --keep-open --title=\"Cropped ${cropffmpegValue}\"" >> "${run_4Screen}"
		printf '%s\n' "exit 0" >> "${run_4Screen}"

		chmod +x "${run_4Screen}"
		
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "${LIGHTYELLOWBOLD}=========================================================================${NC}"
		. "_echoMsg.sh" "Crop Select –"
		. "_echoMsg.sh" "ffmpeg: ${cropffmpegValue}"
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" ""

		read -r -p "=> ${LIGHTYELLOWBOLD}[1]${NC} view video with cropping option, ${LIGHTYELLOWBOLD}[2]${NC} use default cropping ${cropffmpegValue}, ${LIGHTGREENBOLD}[press Return]${NC} to continue without cropping " response
		case ${response} in
			[1] )  																			# view video option
				printf '%s\n\n' "${LIGHTYELLOWBOLD}Cropping${NC} will denoted by a ${UNDERLINE}white border${NC} in the video"
																							# open the video in a detached screen
				screen -dm -S ffmpegCrop /tmp/run_ffmpegCrop.sh

				read -r -p "=> ${LIGHTYELLOWBOLD}[1]${NC} crop using ${cropffmpegValue}, ${LIGHTYELLOWBOLD}[press Return]${NC} to continue without cropping " response
				case ${response} in
					[1] )																	# use ffmpeg
						cropValue="${cropffmpegValue}"
					;;
				esac
																							# stop mpv
				pkill mpv	
			;;
		esac
																							# clean up
		rm -f "/tmp/run_ffmpegCrop.sh"
	fi

	if [ "${cropValue//:}" != "0000" ]; then
		echo "${cropValue}" > "${CROPSDIR}/${fileName}"										# write the crop value out to its crop file
		
		. "_echoMsg.sh" "Using crop value of ${LIGHTYELLOWBOLD}${cropValue}${NC}"
		. "_echoMsg.sh" ""
	fi
}

function ingest_Skips () {
	local i=""
	local j=""
	local skip=""
																							# difference the two arrays to get just the files to skip		
	for i in "${convertFiles_a[@]}"; do
		skip=""
		
		for j in "${transcodeFiles_a[@]}"; do
			[[ "${i}" == "${j}" ]] && { skip="1"; break; }
		done
																							# add to the array
		[[ -n "${skip}" ]] || skippedFiles_a+=("${i}")
	done
	
	for i in "${skippedFiles_a[@]}"; do
																							# move skipped file to its final destination
		mv -f "${i}" "${ORIGINALSDIR}"
	done

	. "_echoMsg.sh" ""
	. "_echoMsg.sh" "Files skipped in this batch (${#skippedFiles_a[@]}):"
	
	for i in "${skippedFiles_a[@]}"; do
		. "_echoMsg.sh" "${RED}${i}${NC}"
	done
}

function pre_Processors () {
	. "_echoMsg.sh" ""
	. "_echoMsg.sh" "Pre-processing files:"
	
	local i=""
	local skipPath=""

	for i in "${convertFiles_a[@]}"; do
		. "_echoMsg.sh" "${i}"
																							# if the file is not a directory or a skip
		if [[ ! -d "${i}" && "${i}" != *"^"* ]]; then
																							# save the file to be transcoded to the array
			transcodeFiles_a+=("${i}")
																							# get the video quality setting
			get_VideoQualitySettings "${i}"
																							# get the crop value, show video cropping if necessary
			get_CropValue "${i}"
		elif [[ "${i}" == *"^"* ]] && [[ -z "${skipPath}" ]]; then
			skipPath="true"
		fi
	done
																							# move all skip files to Originals
	if [[ ! -z "${skipPath}" ]]; then
		ingest_Skips
	fi
}

function rename_File () {
	# ${1}: name of the title, no file extension
	# ${2}: optional filter to use
	# ${3}: database to search
	# ${4}: quality option
	# Return: new filename with extension
	
	local matchVal=""
	local capturedOutput=""
	local fileType=""
	local renamedFile=""
	local updatedName=""
	local need2Rename="true"
	local patternVal=""
	local replaceVal=""
	local i=""
	
	fileType=$(. "_fileType.sh" "${1}")														# get the type of file, movie, tv show, multi episode, extra, skip
	
	. "_echoMsg.sh" "Rename file type: ${fileType}" ""
	
	case "${fileType}" in																	# process the file based on file type
		skip )						
			capturedOutput="${1}.${outExt_}" 												# nothing to see here, just return the passed value
		;;
			
		multi* )
			local matchLoc=""
			local YYVal=""
			local ZZVal=""
			
			matchVal="${fileType##*/}"														# get the embedded matched value out of the string							
		
			capturedOutput="${1%${matchVal}*}"												# remove the original matched text
			capturedOutput="${capturedOutput//_/ }"											# convert any underscores to spaces
			capturedOutput="${capturedOutput#*+}"											# remove any plus characters from the front of the string
			capturedOutput=$(echo "${capturedOutput}" | awk '{print tolower($0)}') 			# lowercase the original text
			capturedOutput=$(echo "${capturedOutput}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text

			matchLoc=$(expr "${matchVal}" : '^.*[Ee]') 										# find the last 'E' in the matched text
			matchVal=$(echo "${matchVal}" | awk '{print tolower($0)}') 						# lowercase the matched text
			matchVal=$(echo ${matchVal:0:(${matchLoc}-1)}-${matchVal:(${matchLoc}-1)})  	# structure the matched text as sXXeYY-eZZ
			
			if [[ ${#matchVal} -lt 10 ]]; then												# need to add leading zero's?
				if [[ "${matchVal}" =~ ([s][0-9]+) ]]; then									# if matchVal is not structured as sXX
					patternVal=${BASH_REMATCH[1]//[^0-9]/}									# get the pattern of numbers after the 's'
					replaceVal="$(printf "%02d" "${patternVal}")"							# pad with a leading zero

					matchVal=${matchVal/${patternVal}/${replaceVal}}						# replace the first occurance of the pattern value with the replacement value in the matchVal
				fi

				YYVal="${matchVal%-*}"														# get the sXXeYY portion
				ZZVal="${matchVal#*-}"														# get the eZZ portion

				if [[ "${YYVal}" =~ ([e][0-9]+) && ${#YYVal} -lt 6 ]]; then					# if matchVal is not structured as eYY
					patternVal=${BASH_REMATCH[1]//[^0-9]/}									# get the pattern of numbers after the 'e'
					replaceVal="$(printf "%02d" "${patternVal}")"
					replaceVal=${YYVal/%${patternVal}/${replaceVal}}						# pad with a leading zero from the back of the string

					matchVal=${matchVal//${YYVal}/${replaceVal}}							# replace eY with eYY
				fi

				if [[ "${ZZVal}" =~ ([e][0-9]+) && ${#ZZVal} -lt 3 ]]; then					# if matchVal is not structured as eZZ
					patternVal=${BASH_REMATCH[1]//[^0-9]/}									# get the pattern of numbers after the 'e'
					replaceVal="$(printf "%02d" "${patternVal}")"
					replaceVal=${ZZVal//${patternVal}/${replaceVal}}						# pad with a leading zero

					matchVal=${matchVal//${ZZVal}/${replaceVal}}							# replace eZ with eZZ
				fi
			fi

			capturedOutput="${capturedOutput} - ${matchVal}.${outExt_}" 					# final output showTitle - sXXeYY-eZZ.ext
		;;
			
		tvshow* )
			need2Rename="false"
																							# need to strip + if present and rename the file first
			mv -f "${OUTDIR}/${1}.${outExt_}" "${OUTDIR}/${1#*+}.${outExt_}"
			
			capturedOutput=$(filebot -rename "${OUTDIR}/${1#*+}.${outExt_}" -non-strict --order "dvd" --db "${3}" --format "${2}")
		;;
		
		movie )
			need2Rename="false"
			capturedOutput=$(filebot -rename "${OUTDIR}/${1}.${outExt_}" -non-strict)
		;;
		
		extra )
			local tempName=""
			local labelInfo=""
			local fileBotName=""
			
			tempName="${1%'%'*}"															# get the title name
			
			labelInfo="${1#*%}"																# get the extras label
			
			if [[ ${1} == *"#"* ]]; then													# legacy tag
				tempName="${1%%#*}"															# get the title name
				
				labelInfo="${1#*#}"															# get the extras label
			fi
			
			tempName="${tempName#*+}"														# remove any plus characters from the front of the string
			labelInfo="${labelInfo%%_*}"													# strip off any trailing _tXX
																							# movie, do not actually rename the file, just get the name
			capturedOutput=$(filebot -rename "${OUTDIR}/${1}.${outExt_}" -non-strict --action test)
			
			fileBotName="${capturedOutput##*[}"												# delete the longest match of "[" from the front of capturedOutput 
			fileBotName="${fileBotName%]*}"													# delete the shortest match of "]" from the back of capturedOutput, leaving filename.ext
			fileBotName="${fileBotName##*/}"												# in case of error in renaming, delete the longest match of "/" from the front of capturedOutput
			
			capturedOutput="${fileBotName%.*}%${labelInfo}.${outExt_}"						# put the title back together with the extras label
			
			if [[ ${1} == *"#"* ]]; then													# legacy tag
				capturedOutput="${fileBotName%.*}#${labelInfo}.${outExt_}"					# put the title back together with the extras label
			fi
		;;
		
		special* )
			local specialDescpt=""
			
			matchVal="${fileType##*/}"														# get the embedded matched value out of the string							
		
			capturedOutput="${1%${matchVal}*}"												# remove the original matched text
			capturedOutput="${capturedOutput//_/ }" 										# convert any underscores to spaces
			capturedOutput="${capturedOutput#*+}"											# remove any plus characters from the front of the string
			capturedOutput=$(echo "${capturedOutput}" | awk '{print tolower($0)}') 			# lowercase the original text
			capturedOutput=$(echo "${capturedOutput}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text

			matchVal=$(echo "${matchVal}" | awk '{print tolower($0)}') 						# lowercase the matched text

			if [[ "${matchVal}" =~ ([e][0-9]+) && ${#matchVal} -lt 6 ]]; then				# if matchVal is not structured as s00eYY
				patternVal=${BASH_REMATCH[1]//[^0-9]/}										# get the pattern of numbers after the 'e'
				replaceVal="$(printf "%02d" "${patternVal}")"								# pad with a leading zero

				matchVal=${matchVal//${patternVal}/${replaceVal}}							# replace eY with eYY
			fi
			
			specialDescpt=$(. "_trimString.sh" "${1##*%}")									# get the description of the of the special
			
			if [[ ${1} == *"#"* ]]; then													# legacy tag
				specialDescpt=$(. "_trimString.sh" "${1##*#}")								# get the description of the of the special
			fi
			
			specialDescpt="${specialDescpt%%_*}"											# remove any underscores

			capturedOutput="${capturedOutput} - ${matchVal} - ${specialDescpt}.${outExt_}"	# final output showTitle - s00eYY - description.ext
		;;
	esac
	
	renamedFile=${capturedOutput##*[}														# delete the longest match of "[" from the front of capturedOutput 
	renamedFile=${renamedFile%]*}															# delete the shortest match of "]" from the back of capturedOutput, leaving filename.ext
	renamedFile=${renamedFile##*/}															# in case of error in renaming, delete the longest match of "/" from the front of capturedOutput
	
	if [[ "${capturedOutput}" =~ (already exists) ]]; then									# duplicate file?
		need2Rename="true"
		
		declare -a dupFiles_a
		dupFiles_a=( "${OUTDIR}"/* )														# get a list of filenames in the output directory
		
		local fileExists=""
		local loopCounter=2																	# start at two
		
		for i in "${dupFiles_a[@]}"; do
			fileExists=${renamedFile%.*}
			
			fileExists="${fileExists}_${loopCounter}.${outExt_}"							# get the filename to look for
			
			if [[ ! -e "${OUTDIR}/${fileExists}" ]]; then
																							# file does not exist in the output directory, exit the loop
				break
			fi
			
			(( loopCounter++ ))
		done
		
		renamedFile="${renamedFile%.*}_${loopCounter}.${outExt_}"
	fi

	if [[ "${4%|*}" != "0" ]]; then
		if [[ "${fileType}" == "movie" || "${fileType}" == *"tvshow"* ]]; then
			updatedName="${renamedFile%.*}.${4#*|}.${outExt_}"
																							# rename the file to the correct final name
			mv -f "${OUTDIR}/${renamedFile}" "${OUTDIR}/${updatedName}"
			renamedFile="${updatedName}"													# update to the correct final name
		else
																							# rename the file with the quality setting
			renamedFile="${renamedFile%.*}.${4#*|}.${outExt_}"
		fi
	fi
	
	if [[ "${need2Rename}" == "true" ]]; then
		mv -f "${OUTDIR}/${1}.${outExt_}" "${OUTDIR}/${renamedFile}"						# rename the file to the correct final name
	fi
	
	echo "${renamedFile}"																	# pass back the new filename
	
	. "_echoMsg.sh" "Renaming file to '${renamedFile}'" ""
}

function rename_LogFile () {
	# ${1}: file path
	# ${2}: quality setting

	local fileName=""
	local origLog=""
	local logPath=""
	local logTags=""
	local dateTimeStamp=""
	
	dateTimeStamp=$(date +"%H%M%S_%m%d%Y")
	
%H%M%S%m%d%Y
	
	logTags="${logTag_},${2}"
																							# construct the new log filename
	fileName="${1##*/}"
	origLog="${OUTDIR}/${fileName%.*}.${outExt_}.log"
	logPath="${LOGDIR}/${fileName%.*}.${outExt_}.${2}.${dateTimeStamp}.log"
																							# add the log file path to the array
	logFiles_a+=("${logPath}")
																							# rename the log file
	mv -f "${origLog}" "${logPath}"
	
	. "_finderTag.sh" "${logTags}" "${logPath}"												# set Finder tags after final move	
}

function final_Statistics () {
	# ${1}: timestamp
	
	local TAB=$'\t'
	local queryS=""
	local queryB=""
	local queryR=""
	local queryOut=""
	local fileName=""
	local loopDetails=""
	local qualityOption=""
	local i=""
	
	if [[ "${#logFiles_a[@]}" -gt 0 ]]; then
																							# files were transcoded
		for i in "${logFiles_a[@]}"; do
			qualityOption="${i##*.--}"
			qualityOption="--${qualityOption%.*}"
			fileName="${i##*/}"																# get the filename
			fileName="${fileName%%.${outExt_}*}.${outExt_}"									# construct the complete filename

			queryT=$(query-handbrake-log t --tabular "${i}")  								# no value
			queryS=$(query-handbrake-log s --tabular "${i}")								# fps
			queryB=$(query-handbrake-log b --tabular "${i}")								# kbps
			queryR=$(query-handbrake-log r --tabular "${i}")								# no value

			if [[ "${#logFiles_a[@]}" != "0" ]]; then
				queryOut="${queryOut}${fileName//%/%%}${TAB}${qualityOption}${TAB}${queryT%${TAB}*}${TAB}${queryS%${TAB}*}${TAB}${queryB%${TAB}*}${TAB}${queryR%${TAB}*}\n"
			else
				queryOut="${fileName//%/%%}${TAB}${qualityOption}${TAB}${queryT%${TAB}*}${TAB}${queryS%${TAB}*}${TAB}${queryB%${TAB}*}${TAB}${queryR%${TAB}*}\n"
			fi
		done
	
		loopDetails="${#logFiles_a[@]} files"
	
		if [[ "${#logFiles_a[@]}" -eq 1 ]]; then
			loopDetails="${#logFiles_a[@]} file"
		fi
	
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Transcode statistics –"
		. "_echoMsg.sh" "It took ${1} to transcode ${loopDetails}"
		. "_echoMsg.sh" ""
																							# print the report to the Terminal
		printf '%s' "${UNDERLINE}"
		(printf "TITLE${TAB}QUALITY${TAB}TIME${TAB}SPEED (fps)${TAB}BITRATE (kbps)${TAB}RATE ${NL}" ; printf "${LIGHTBLUEBOLD}\n" ; printf "${queryOut}") | column -ts "${TAB}"
		printf '%s' "${NC}"
																							# convert tabs to spaces
		queryOut="$(echo -e ${queryOut/${TAB}/ })"
	
		declare -a logValue_a
																							# save IFS
		saveIFS=${IFS}
		IFS=$'\n' read -r -a logValue_a <<< "${queryOut}"									# convert string to array based on newline
		IFS=${saveIFS}																		# restore IFS
																							# echo stats header to log
		. "_echoMsg.sh" "TITLE   SETTING   TIME   SPEED (fps)   BITRATE (kpbs)   RATE" ""

		for i in "${logValue_a[@]}"; do
																							# echo each stat to log
			. "_echoMsg.sh" "${i}" ""
		done	
	fi
}

function time_Stamp () {
	# ${1}: flag, "start" - start timer, "stop" - stop timer
	
	local timeStamp=""
	local timeStampEnd=""
	local tvVersion=""
	local i=""
	
	if [[ "${1}" == "start" ]]; then
																							# set the start of the duration timer
		SECONDS=0
		
		timeStamp=$(date +"%r, %D")
		tvVersion=$(transcode-video --version)
		tvVersion=$(echo "${tvVersion}" | tr "\n" " ")										# strip out the carriage return
		
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Transcode ${LIGHTBLUE}${VERSCURRENT}${NC} (${SCRIPTVERS})"
		. "_echoMsg.sh" "Copyright (c) 2016-2017 Brent Hayward"
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "${tvVersion}"
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Transcode started @ ${LIGHTGREENBOLD}${timeStamp}${NC}"
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Files to be transcoded in this batch (${#convertFiles_a[@]}):"
		
		for i in "${convertFiles_a[@]}"; do
			. "_echoMsg.sh" "${LIGHTBLUEBOLD}${i}${NC}"
		done
		
		if [[ "${#convertFiles_a[@]}" == "1" ]]; then
			. "_sendNotification.sh" "Transcode Started" "${timeStamp}" "${#convertFiles_a[@]} file to convert"
			
		else
			. "_sendNotification.sh" "Transcode Started" "${timeStamp}" "${#convertFiles_a[@]} files to convert"
		fi		
	else
		local duration=0
		local hours=0
		local minutes=0
		local seconds=0
		
		duration=${SECONDS} 																# set the stop time
		hours=$((${duration} / 3600))
		minutes=$(((${duration} / 60) % 60))
		seconds=$((${duration} % 60))
		
		if [[ "${hours}" != "0" ]];then
			if [[ "${hours}" != "1" ]]; then
				timeStamp="${hours} hours, "
			else
				timeStamp="${hours} hour, "
			fi	
		fi

		if [[ "${minutes}" != "0" ]]; then
			if [[ "${minutes}" != "1" ]]; then
				timeStamp=${timeStamp}"${minutes} minutes "
			else
				timeStamp=${timeStamp}"${minutes} minute "
			fi
		fi
		
		if [[ "${seconds}" != "0" ]]; then
			if [[ "${seconds}" != "1" ]]; then
				timeStamp=${timeStamp}"${seconds} seconds"
			else
				timeStamp=${timeStamp}"${seconds} second"
			fi
		else
			timeStamp="Less than a second"
		fi
		
		timeStampEnd=$(date +"%r, %D")
		
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Transcode completed @ ${RED}${timeStampEnd}${NC}"

		final_Statistics "${timeStamp}"
		
		. "_echoMsg.sh" ""
		
		if [[ "${#transcodeFiles_a[@]}" == "1" ]]; then
			. "_sendNotification.sh" "Transcode Complete" "${transcodeFiles_a[0]##*/}" "converted in ${timeStamp}" "Hero"
		else
			. "_sendNotification.sh" "Transcode Completed" "in ${timeStamp}" "${#transcodeFiles_a[@]} files converted" "Hero"
		fi
	fi	
}

function send_2Remote () {
	# ${1}: file path
	
	local tempDir=""
	local file2Send=""
	local sshConnection=""
	local msgTxt=""
	local upperLimit=3
	local sleepTime=10
	local i=1
	
																							# get the path to temporary destination
	tempDir="/tmp/"
	sshConnection="${sshUser_}:${rsyncPath_}"												# e.g., sadmin@media.mdm2195.com:"${rsyncPath_}"
	file2Send="${1}"

	for ((i=1; i<=upperLimit; i++)); do
		msgTxt="transcoded"
		
		if [[ "${file2Send}" != *"${outExt_}"* ]]; then
			msgTxt="original"
		fi
		
		. "_echoMsg.sh" "Moving ${msgTxt} file ${file2Send} to remote destination ${rsyncPath_}"
																							# rsync the file over to the Transcode destination, include xattr (Finder info!)
		/usr/local/bin/rsync -ahX --info=progress2 --temp-dir="${tempDir}" --delay-updates --rsync-path="/usr/local/bin/rsync" "${file2Send}" "${sshConnection}"
																							# if an error occurred
		if [[ "${?}" -ne "0" ]]; then
			. "_echoMsg.sh" "Retrying rsync to ${rsyncPath_} in ${sleepTime} seconds..."
			sleep ${sleepTime}																# pause and try again
		else			
			break																			# all good, we're done
		fi
	done
	
	if [[ ${i} -gt 3 ]]; then
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "${REDBOLD}Unable to rsync. Exiting...${NC}"
		. "_echoMsg.sh" ""
		
		exit 1																				# not able to rsync, bailout
	fi
}

function transcode_Video () {
	local titleName=""
	local cropFile=""
	local cropOption=''
	local applyTag=""
	local subTitleFile=""
	local subTitleOption=""
	local fileType=""
	local showTitle=""
	local renamedPath=""
	local hdbrkOption=''
	local audioOption=''
	local audioWidth=''
	local qualityOption=''
	local qualityOptionStr=""
	local msgTxt=""
	local outputDestination=""
	local i=0
	local j=0
	
	audioOption="--add-audio all"
	audioWidth="--audio-width other=double"
	
	declare -a qualitySettings_a															# create the array for holding the video quality setting for each transcode
	
	. "_echoMsg.sh" ""
	
	for i in "${!transcodeFiles_a[@]}"; do
																							# get the transcode file path
		input="${transcodeFiles_a[${i}]}"
																							# get the quality settings for this transcode and put into the qualitySettings_a array
		get_ThisQualitySetting "${i}"
																							# need to reset j to 0 for every iteration of i
		j=0
		for j in "${!qualitySettings_a[@]}"; do
			 																				# get the title of the video, no file extension
		    titleName="$(basename "${input}" | sed 's/\.[^.]*$//')"
		    cropFile="${CROPSDIR}/${titleName}.txt"
																							# get the quality setting for this transcode
			qualityOption="${qualitySettings_a[${j}]}"
			qualityOptionStr="${qualityOption}"												# need an unalterd copy for passing to other functions

			if [[ "${qualityOption}" == "--default" ]]; then
																							# default quality setting is an empty string
				qualityOption=""
			fi
	
			if [[ "${titleName}" =~ ([Ss][0-9]+[Ee][0-9]+) ]]; then
				fileType="tvshow"															# TV show
				applyTag=${tvTag_}
				hdbrkOption="--handbrake-option decomb"
			else
				fileType="movie"															# Movie
				applyTag=${movieTag_}
				hdbrkOption=''
			fi
		
			if [[ "${input}" == *"+"* ]]; then
				hdbrkOption="--handbrake-option decomb"										# need to decomb this file
			fi

		    if [[ -f "${cropFile}" ]]; then
		        cropOption="--crop $(cat "${cropFile}")" 									# get the crop value
		    else
		        cropOption=''
		    fi

			subTitleFile="${SUBSDIR}/${titleName}.txt"										# get the title of the video, no file extension
		
		    if [[ -f "${subTitleFile}" ]]; then
		        subTitleOption="--burn-subtitle $(cat "${subTitleFile}")" 					# get the subtitle file
		    else
		        subTitleOption=''
		    fi
		
			outputDestination="${LIGHTGREENBOLD}local${NC}"									# set the output destination
		
			if [[ ! -z "${sshUser_}" ]] && [[ ! -z "${rsyncPath_}" ]] && [[ "${#qualitySettings_a[@]}" -eq 1 ]]; then
				outputDestination="remote"
			fi
		
			msgTxt="${input##*/}"															# remove path

			. "_echoMsg.sh" "Transcoding ${LIGHTBLUEBOLD}${msgTxt##*/} with ${qualityOptionStr} -${NC}"
			. "_echoMsg.sh" "Delivering output to ${outputDestination} destination"
			. "_echoMsg.sh" ""
			
			. "_sendNotification.sh" "Transcoding" "${input##*/}" "with ${qualityOptionStr} video quality"
																							# transcode the file
			transcode-video ${qualityOption} --output "${OUTDIR}" ${outExtOption_} ${cropOption} ${subTitleOption} ${hdbrkOption} ${audioOption} ${audioWidth} "${input}"
																							# rename the log file to include the video quality setting
			rename_LogFile "${input}" "${qualityOptionStr}"
			
			if [[ "${fileType}" == "tvshow" ]]; then										# TV Show
				if [[ "${renameFile_}" == "true" || "${renameFile_}" == "tv" ]]; then
																							# rename the file. For TV show: {Name} - {sXXeXX} - {Episode Name}.{ext}
					showTitle=$(rename_File "${titleName}" "${tvShowFormat_}" "TheTVDB" "${j}|${qualityOptionStr}")
				fi	
			else																			# movie
				if [[ "${renameFile_}" == "true" || "${renameFile_}" == "movie" ]]; then
																							# rename the file. For movie: {Name} {(Year of Release)}.{ext}
					showTitle=$(rename_File "${titleName}" "${movieFormat_}" "" "${j}|${qualityOptionStr}")
				fi
			fi
																							# renamed file with full path
			renamedPath="${OUTDIR}/${showTitle}"
																							# set the file 'title' metadata
			. "_metadataTag.sh" "${renamedPath}" "title"
																							# set Finder tags
			. "_finderTag.sh" "${applyTag},${qualityOptionStr}" "${renamedPath}" "${extrasTag_}"
																							# transfer completed files to a Transcode destination if only one 
			if [[ "${outputDestination}" == "remote" ]]; then
																							# copy transcoded file to the remote destination
				send_2Remote "${renamedPath}" 
			
				if [[ "${deleteAfterRemoteDelivery_}" == "true" ]]; then
					rm -f "${renamedPath}"													# remove the completed file
				fi
			fi
		
			if [[ -e "${renamedPath}" ]]; then
																							# move the transcoded file to final location if flag is set
				renamedPath=$(. "_moveTranscoded.sh" "${renamedPath}" "${completedPath_}" "${movieFormat_}" "${tvShowFormat_}")
				
				. "_echoMsg.sh" ""
				. "_echoMsg.sh" "Moved transcoded file ${showTitle} to ${renamedPath}"
			fi
		done
		
		rm -f "${cropFile}"																	# remove the crop file
	done
																							# completed all transcoded successfully
	input=""
}

function post_Processors () {
	local i=""
	local index=0
	
	find "${OUTDIR}" -name '*.log' -exec mv -f {} "${LOGDIR}" \;							# move all the log files to Logs
	
	. "_echoMsg.sh" ""
	. "_echoMsg.sh" "Moved log files to ${LOGDIR}"
	
	if [[ "${deleteWhenDone_}" == "true" ]]; then											# check the deleteWhenDone_ flag and proceed accordingly
		. "_echoMsg.sh" "${REDBOLD}Deleting originals${NC}"
		
		for i in "${transcodeFiles_a[@]}"; do
			rm -fr "${i}"																	# remove all the original files
		done
	else
		. "_echoMsg.sh" ""
																							# loop through the transcoded files and original files
		for index in "${!transcodeFiles_a[@]}"; do
			i="${transcodeFiles_a[${index}]}"
			
			. "_finderTag.sh" "${convertedTag_}" "${i}" "${extrasTag_}"						# set the original file Finder tags to indicate it has been processed

			if [[ -e "${i}" ]]; then
				if [[ ! -z "${sshUser_}" ]] && [[ ! -z "${rsyncPath_}" ]] && [[ "${videoQuality_a[${index}]}" != *","* ]]; then
																							# copy original file to the remote destination
					send_2Remote "${i}"
					
					send_2Remote "${logFiles_a[${index}]}"

					if [[ "${deleteAfterRemoteDelivery_}" == "true" ]]; then
						rm -f "${i}"														# remove the original file
					fi
				fi
																							# file still exists
				if [[ -e "${i}" ]]; then					
					. "_moveOriginal.sh" "${i}" "${ORIGINALSDIR}"							# move the original file to Originals
					
					. "_echoMsg.sh" ""
					. "_echoMsg.sh" "Moved original file ${i} to ${ORIGINALSDIR}"
				fi
			fi								
		done
		
		. "_echoMsg.sh" ""
																							# loop through the skipped files
		index=0
		for index in "${!skippedFiles_a[@]}"; do
			i="${ORIGINALSDIR}/${skippedFiles_a[${index}]##*/}"
			
			if [[ -e "${i}" ]]; then
				if [[ ! -z "${sshUser_}" ]] && [[ ! -z "${rsyncPath_}" ]]; then
																							# copy skipped file to the remote destination
					send_2Remote "${i}"
					
					if [[ "${deleteAfterRemoteDelivery_}" == "true" ]]; then
						rm -f "${i}"														# remove the skipped file
					fi
				fi
			fi
		done
	fi
}

function clean_Up () {
	local titleName=""
																							# delete the semaphore file so processing can be started again
	rm -f "${WORKINGPATH}"
																							# process was halted, need to remove the last file, log and crops file that was not finished transcoding
	if [[ ! -z "${input}" ]]; then
		titleName="$(basename "${input}" | sed 's/\.[^.]*$//')"
		titleName="${OUTDIR}/${titleName}.${outExt_}"
		rm -f "${titleName}"
		rm -f "${titleName}.log"
		rm -rf "${CROPSDIR}"/*
		
		. "_sendNotification.sh" "Transcode Cancelled"
	fi
}

function handle_Switches () {
	# ${1}: switches
	
	case "${1}" in
		*--version* | *-v* )
			printf "\nTranscode ${LIGHTBLUEBOLD}${VERSCURRENT}${NC}\n"
			printf "Copyright (c) 2016 Brent Hayward\n\n"
			transcode-video --version
			printf "\n"
			
			exit 2
		;;
		
		*--help* | *-h* )
			printf '\n%s\n\n' "${LIGHTBLUEBOLD}Transcode${NC}, tools to batch transcode and process videos"
			printf "Works best with Blu-ray or DVD rip\n"
			printf "Automatically determines target video bitrate, number of audio tracks, etc.\n\n"
			printf "Usage: drop .mkv files into /Transcode/Convert to transcode and process\n\n"
			printf "Other options:\n"
			echo -e "-h, --help\t\tdisplay this help and exit"
			echo -e "-v, --version\t\toutput version information and exit"
			echo -e "-r, --recompress\trecompress all originals located in /Transcode/Originals"
			printf "\n"
		
			exit 2
		;;
		
		*--recompress* | *-r* )
			printf '\n%s\n\n' "${LIGHTBLUEBOLD}Recompress Originals${NC}"  
			printf "Automatically recompresses the entire library of original .mkv files located in /Transcode/Originals\n"
			printf "\n"
			
			exit 2
		;;
		
		* )																					# exit if no files to convert
			if [[ ${#convertFiles_a[@]} -gt 0 ]] && [[ "${convertFiles_a[0]}" == "${CONVERTDIR}/*" ]]; then
				input=""
				. "_echoMsg.sh" ""
				. "_echoMsg.sh" "${REDBOLD}Exiting${NC}, no files found in ${CONVERTDIR} to transcode."

				. "_sendNotification.sh" "Transcode Stopped" "No files to convert"

				exit 1
			fi	
		;;
	esac
}

function __main__ () {
	handle_Switches "${@}"
	
	printf '\e[8;13;154t'																	# set the Terminal window size to 154x5
	echo -n -e "\033]0;Transcode\007"														# set the Terminal window title
	printf "\033c"																			# clear the Terminal screen
	
	
	time_Stamp "start"																		# start the duration timer

	get_Prefs
	build_Resources
	pre_Processors
	transcode_Video
	post_Processors

	time_Stamp "stop"																		# stop the duration timer
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors

define_Constants

touch "${WORKINGPATH}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles_a
convertFiles_a=( "${CONVERTDIR}"/* )												   		# get a list of filenames with path to convert

declare -a transcodeFiles_a																	# create the array for holding only the transcoded files
declare -a videoQuality_a																	# create the array for holding the video quality setting for each file
declare -a skippedFiles_a																	# create the array for holding the skipped files
declare -a logFiles_a																		# create the array for holding the log file for each file

__main__ "${@}"

exit 0