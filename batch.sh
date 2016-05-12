#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/batchTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch
#	Copyright (c) 2016 Brent Hayward			
#	
#	
#	This script is a wrapper to Don Melton's batch script which transcodes DVD and Blu-Ray content.
#	https://github.com/donmelton/video_transcoding
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
                                                     							# define version number
	local versStamp="Version 1.4.7, 05-11-2016"
	readonly scriptVers="${versStamp:8:${#versStamp}-20}"
	                                                            				# define script name
	readonly scriptName="batch"
																				# define the minimum supported and running OS versions
	readonly minOS=10.11
	readonly osVersion=$(sw_vers -productVersion)
																				# get the paths
	local DIR=""
	local SOURCE="${BASH_SOURCE[0]}"
	
	while [ -h "${SOURCE}" ]; do 												# resolve ${SOURCE} until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
		SOURCE="$(readlink "${SOURCE}")"
		[[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" 						# if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	
	readonly scriptPath="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
	
	readonly workDir="${scriptPath}"
	readonly cropsDir="${workDir}/Crops"
	readonly convertDir="${workDir}/Convert"
	readonly logDir="${workDir}/Logs"
	readonly subsDir="${workDir}/Subtitles"
	readonly remoteDir="${workDir}/Remote"
	readonly outDir="${workDir}/Completed"
	readonly originalsDir="${outDir}/Originals"
	readonly libDir="${HOME}/Library"
	
	readonly outDirOption="--output ${outDir}"
	
	readonly queuePath="${workDir}/queue.txt"
	readonly prefPath="${workDir}/Prefs.txt"
	readonly workingPath="${libDir}/Preferences/com.videotranscode.batch.working.plist"
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	
	readonly sh_matchVal="${appScriptsPath}/_matchVal.sh"
	readonly sh_sendNotification="${appScriptsPath}/_sendNotification.sh"
	readonly sh_fileType="${appScriptsPath}/_fileType.sh"
	readonly sh_metadataTag="${appScriptsPath}/_metadataTag.sh"
	readonly sh_finderTag="${appScriptsPath}/_finderTag.sh"
	readonly sh_readPrefs="${appScriptsPath}/_readPrefs.sh"
	readonly sh_writePrefs="${appScriptsPath}/_writePrefs.sh"
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"									# echo to the Terminal
	fi
    echo "${1}" 2>&1 | logger -t batch.cmd			# echo to syslog
}

function if_Error () {
	# ${1}: last line of error occurence
	# ${2}: error code of last command
	
	local lastLine="${1}"
	local lastErr="${2}"
																		# if lastErr > 0 then echo error msg and log
	if [[ ${lastErr} -eq 0 ]]; then
		echo_Msg ""
		echo_Msg "Something went awry :-("
		echo_Msg "Script error encountered $(date) in ${scriptName}.sh: line ${lastLine}: exit status of last command: ${lastErr}"
		echo_Msg "Exiting..."
		
		exit 1
	fi
}

function get_Prefs () {
																				# create the default preferences file if it does not exist	
	if [ ! -e "${prefPath}" ]; then
	   . "${sh_writePrefs}" "${prefPath}"
	fi
	
	. "${sh_readPrefs}" "${prefPath}"											# read in the preferences from Prefs.txt
}

function trim() {
	# ${1}: variable to trim spaces from
	# Returns: variable with spaces removed from the front and back
	
    local var="$*"

    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters

    echo "${var}"
}

function build_Resources () {
																		# make sure all the directories are in place and create if not
	if [ ! -d "${convertDir}" ]; then
	  	mkdir -p "${convertDir}"
	fi	
	
	if [ ! -d "${outDir}" ]; then
	  mkdir -p "${outDir}"
	fi
	
	if [ ! -d "${originalsDir}" ]; then
	  mkdir -p "${originalsDir}"
	fi
	
	if [ ! -d "${cropsDir}" ]; then
	  	mkdir -p "${cropsDir}"
	fi
	
	if [ ! -d "${logDir}" ]; then
	  mkdir -p "${logDir}"
	fi
	
	if [ ! -d "${subsDir}" ]; then
	  mkdir -p "${subsDir}"
	fi
	
	if [ ! -d "${remoteDir}" ]; then
	  mkdir -p "${remoteDir}"
	fi
}

function pre_Processors () {
	echo_Msg "Pre-processing files"
	
	local capturedOutput=""
	local cropValue=""
	local fileNameExt=""
	local fileName=""
	local queueValue=""
	
	for i in "${convertFiles[@]}"; do
		if [ ! -d "${i}" ]; then
			capturedOutput=$(detect-crop "${i}")							# run detect-crop tool against the file

			cropValue="${capturedOutput##*--crop}"
			cropValue="${cropValue%% /*}"
			cropValue="${cropValue// /}"	 								# remove any white spaces
	
			fileNameExt="${i##*/}"											# filename with extension
			fileName="${fileNameExt%.*}.txt"								# filename without extension

			if [ "${cropValue//:}" != "0000" ]; then
				echo ${cropValue} > "${cropsDir}/${fileName}"				# write the crop value out to its crop file
			fi
	
			queueValue="${convertDir}/${fileNameExt}"
			echo ${queueValue} >> "${queuePath}"							# write the file path to the queue file
		fi
	done
}

function rename_File () {
	# ${1}: name of the title, no file extension
	# ${2}: optional filter to use
	# ${3}: database to search
	# Return: new filename with extension
	
	local matchVal=""
	local capturedOutput=""
	local fileType=""
	local renamedFile=""
	
	fileType=$(. "${sh_fileType}" "${1}")																				# get the type of file, movie, tv show, multi episode, extra, skip
	
	echo_Msg "Renaming: File type is ${fileType}" ""
	
	case "${fileType}" in																								# process the file based on file type
		skip )						
			capturedOutput="${1}.${outExt}" 																			# nothing to see here, just return the passed value
		;;
		
		multi* )
			matchVal="${fileType##*/}"																					# get the embedded matched value out of the string							
		
			capturedOutput="${1%${matchVal}*}"																			# remove the original matched text
			capturedOutput="${capturedOutput//_/ }"																		# convert any underscores to spaces
			capturedOutput=$(echo ${capturedOutput} | awk '{print tolower($0)}') 										# lowercase the original text
			capturedOutput=$(echo ${capturedOutput} |  awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text

			local matchLoc=$(expr "${matchVal}" : '^.*[Ee]') 															# find the last 'E' in the matched text
			matchVal=$(echo ${matchVal} | awk '{print tolower($0)}') 													# lowercase the matched text
			matchVal=$(echo ${matchVal:0:(${matchLoc}-1)}-${matchVal:(${matchLoc}-1)})  								# structure the matched text as sXXeYY-eZZ

			capturedOutput="${capturedOutput} - ${matchVal}.${outExt}" 													# final output showTitle - sXXeYY-eZZ.ext
		;;

		tvshow* )
			capturedOutput=$(filebot -rename --order "dvd" --db "${3}" --format "${2}" "${outDir}/${1}.${outExt}")
		;;

		movie )
			capturedOutput=$(filebot -rename "${outDir}/${1}.${outExt}")
		;;

		extra )
			local tempName="${1%%#*}"																							# get the title
			tempName="${tempName#*+}"																							# remove any plus characters from the front of the string
			local labelInfo="${1#*#}"																							# get the extras label
			labelInfo="${labelInfo%%_*}"																						# strip off any trailing _tXX
			
			if [ -z "${2}" ]; then
				capturedOutput=$(filebot -rename -non-strict "${outDir}/${tempName}.${outExt}")									# movie
			else
				capturedOutput=$(filebot -rename -non-strict --db "${3}" --format "${2}" "${outDir}/${tempName}.${outExt}")		# TV show
			fi
			
			local fileBotName="${capturedOutput##*[}"																			# delete the longest match of "[" from the front of capturedOutput 
			fileBotName="${fileBotName%]*}"																						# delete the shortest match of "]" from the back of capturedOutput, leaving filename.ext
			fileBotName="${fileBotName##*/}"																					# in case of error in renaming, delete the longest match of "/" from the front of capturedOutput
			
			capturedOutput="${fileBotName%.*}#${labelInfo}.${outExt}"															# put the title back together with the extras label
		;;
		
		special* )
			local matchLoc=""
			local specialDescpt=""
			
			matchVal="${fileType##*/}"																					# get the embedded matched value out of the string							
		
			capturedOutput="${1%${matchVal}*}"																			# remove the original matched text
			capturedOutput="${capturedOutput//_/ }" 																	# convert any underscores to spaces
			capturedOutput="${capturedOutput#*+}"																		# remove any plus characters from the front of the string
			capturedOutput=$(echo ${capturedOutput} | awk '{print tolower($0)}') 										# lowercase the original text
			capturedOutput=$(echo ${capturedOutput} |  awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text

			matchLoc=$(expr "${matchVal}" : '^.*[Ee]') 																	# find the last 'E' in the matched text
			matchVal=$(echo ${matchVal} | awk '{print tolower($0)}') 													# lowercase the matched text
			
			specialDescpt=$(trim ${1##*#})																				# get the description of the of the special
			specialDescpt=$(echo ${specialDescpt%%_*})																	# remove any underscores
			
			capturedOutput="${capturedOutput} - ${matchVal} - ${specialDescpt}.${outExt}"					# final output showTitle - s00eYY - description.ext
		;;
	esac
	
	renamedFile=${capturedOutput##*[}													# delete the longest match of "[" from the front of capturedOutput 
	renamedFile=${renamedFile%]*}														# delete the shortest match of "]" from the back of capturedOutput, leaving filename.ext
	renamedFile=${renamedFile##*/}														# in case of error in renaming, delete the longest match of "/" from the front of capturedOutput
	
	if [[ "${capturedOutput}" =~ (already exists) ]]; then								# duplicate file?
		declare -a dupFiles
		dupFiles=( "${outDir}"/* )														# get a list of filenames in the output directory
		
		local fileExists=""
		local loopCounter=2																# start at two
		
		for i in "${dupFiles[@]}"; do
			fileExists=${renamedFile%.*}
			
			fileExists="${fileExists}_${loopCounter}.${outExt}"							# get the filename to look for
			
			if [ ! -e "${outDir}/${fileExists}" ]; then
																						# file does not exist in the output directory, exit the loop
				break
			fi
			
			(( loopCounter++ )) 
		done
		
		renamedFile="${renamedFile%.*}_${loopCounter}.${outExt}"
	fi
	
	mv -f "${outDir}/${1}.${outExt}" "${outDir}/${renamedFile}"							# rename the file to the correct final name
	
	echo "${renamedFile}"																# pass back the new filename
}

function move_Transcoded () {
	# ${1}: path of file to move with filename and extension
	# ${2}: external move location
	# Returns: moved path to the file
	
	local movedPath="${1}"
	local fileName="${1##*/}"
	local extMovePath="${2}"
	local fileType=""
	
	fileType=$(. "${sh_fileType}" "${movedPath}")								# get the type of file, movie, tv show, multi episode, extra, skip
	
	echo_Msg "Moving transcoded: File type is ${fileType}" ""
																				# custom path, not skipping
	if [ -n "${extMovePath}" ]; then
		 																		# what file type
		case "${fileType}" in
			skip )
				echo_Msg "Moving transcoded: nothing to see here, skipping move" ""
			;;

			movie )
				if [ -z "${movieFormat}" ]; then								# the movie format has not been changed
					local moviesDir="${extMovePath}/Movies"
					if [ ! -d "${moviesDir}" ]; then							# create the Movies directory
				  		mkdir -p "${moviesDir}"
					fi
					
					local movieFldrPath="${moviesDir}/${fileName%.*}"			# create the movie titles directory
					if [ ! -d "${movieFldrPath}" ]; then
						mkdir -p "${movieFldrPath}"
					fi
					
					mv -f "${1}" "${movieFldrPath}"								# move the transcoded file to its final destination
				
					movedPath="${movieFldrPath}/${fileName}"
				fi
			;;
				
			tvshow*|multi* )
				if [ "${tvShowFormat}" == "{n} - {'s'+s.pad(2)}e{e.pad(2)} - {t}" ]; then 	# TV Show format has not been changed
					local tvDir="${extMovePath}/TV Shows"
					local showTitle="${fileName}"
					local showDir=""
					local seasonDir=""
					local season=""
					local matchVal=""
					
					matchVal="${fileType##*/}"										# get the matchVal passed back from sh_fileType
					
					if [[ "${matchVal}" =~ ([s][0-9]+) ]]; then						# need to use the if statement to get the season number from the matchVal
						season=${BASH_REMATCH[1]}									# get only SXX
						season=${season//[^0-9]/}									# get only the numbers, strip the 's' out
						season=$(echo ${season} | sed 's/^0*//') 					# remove leading zero's
					fi
					
					showTitle="${showTitle%${matchVal}*}"							# remove the matched value from the showTitle
					showTitle="${showTitle% - *}"				
				
					if [ ! -d "${tvDir}" ]; then									# create the TV Show directory if it does not exist
				  		mkdir -p "${tvDir}"
					fi
				
					showDir="${tvDir}/${showTitle}"									# create the show's title directory if it does not exist
					if [ ! -d "${showDir}" ]; then
				  		mkdir -p "${showDir}"
					fi
				
					seasonDir="${showDir}/Season ${season}"							# create the season directory if it does not exist
					if [ ! -d "${seasonDir}" ]; then
				  		mkdir -p "${seasonDir}"
					fi
			
					mv -f "${1}" "${seasonDir}"										# move the transcoded file to its final destination
				
					movedPath="${seasonDir}/${fileName}"
				fi
			;;
			
			extra )
				local tempName="${fileName%%#*}"										# get the title
				local labelInfo="${fileName#*#}"										# get the extras label
				local extrasType="${labelInfo%%-*}"										# get the extras type
				local extraTitle="${labelInfo#*-}"										# get the extras title
					
				if [ -z "${movieFormat}" ]; then										# the movie format has not been changed
					local moviesDir="${extMovePath}/Movies"
					if [ ! -d "${moviesDir}" ]; then									# create the Movies directory
				  		mkdir -p "${moviesDir}"
					fi
				
					local movieFldrPath="${moviesDir}/${tempName}"
					if [ ! -d "${movieFldrPath}" ]; then								# create the movie titles directory
						mkdir -p "${movieFldrPath}"
					fi
				
					local extrasFldrPath="${movieFldrPath}/${extrasType}"		
					if [ ! -d "${extrasFldrPath}" ]; then								# create the extras directory
						mkdir -p "${extrasFldrPath}"
					fi				
				
					mv -f "${1}" "${extrasFldrPath}/${extraTitle}"						# move the transcoded file to its final destination
			
					movedPath="${extrasFldrPath}/${extraTitle}"
				fi
			;;
		
			special* )
				if [ "${tvShowFormat}" == "{n} - {'s'+s.pad(2)}e{e.pad(2)} - {t}" ]; then 	# TV Show format has not been changed
					local tvDir="${extMovePath}/TV Shows"
					local showTitle="${fileName}"
					local showDir=""
					local seasonDir=""
					local season=""
					local matchVal=""
			
					matchVal="${fileType##*/}"										# get the matchVal passed back from sh_fileType
			
					if [[ "${matchVal}" =~ ([s][0]+) ]]; then						# need to use the if statement to get the season number from the matchVal
						season=${BASH_REMATCH[1]}									# get only SXX
						season=${season//[^0-9]/}									# get only the numbers, strip the 's' out
						season=$(echo ${season} | sed 's/^0*//') 					# remove leading zero's
					fi
			
					showTitle="${showTitle%${matchVal}*}"							# remove the matched value from the showTitle
					showTitle="${showTitle% - *}"				
		
					if [ ! -d "${tvDir}" ]; then									# create the TV Show directory if it does not exist
				  		mkdir -p "${tvDir}"
					fi
		
					showDir="${tvDir}/${showTitle}"									# create the show's title directory if it does not exist
					if [ ! -d "${showDir}" ]; then
				  		mkdir -p "${showDir}"
					fi
		
					seasonDir="${showDir}/Specials"									# create the specials directory if it does not exist
					if [ ! -d "${seasonDir}" ]; then
				  		mkdir -p "${seasonDir}"
					fi
	
					mv -f "${1}" "${seasonDir}"										# move the transcoded file to its final destination
		
					movedPath="${seasonDir}/${fileName}"
				fi
			;;
		esac
	fi
	
	echo "${movedPath}"
}

function move_Original () {
	# ${1}: path of file to move with filename and extension
	# ${2}: external move location
	
	local fileName="${1##*/}"
	local extMovePath="${2}"
	local fileType=""
	
	fileType=$(. "${sh_fileType}" "${1}")										# get the type of file, movie, tv show, multi episode, extra, skip
	
	echo_Msg "Moving original: File type is ${fileType}" ""
																				# custom path, not skipping
	if [ -n "${extMovePath}" ]; then
		 																		# what file type
		case "${fileType}" in
			skip )				
				mv -f "${1}" "${extMovePath}"									# move the transcoded file to its final destination
			;;

			movie )					
				local movieTitle="${fileName%.*}"								# get the title without extension
				movieTitle="${movieTitle//_/ }"									# replace all underscores with spaces
				
				movieTitle=$(echo ${movieTitle} | awk '{print tolower($0)}') 										# lowercase the original text
				movieTitle=$(echo ${movieTitle} | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text
				
				local movieFldrPath="${extMovePath}/${movieTitle}"				# create the movie titles directory
				if [ ! -d "${movieFldrPath}" ]; then
					mkdir -p "${movieFldrPath}"
				fi
				
				mv -f "${1}" "${movieFldrPath}"									# move the original file to its final destination
			;;
				
			tvshow*|multi* )
				local tvDir="${extMovePath}"
				local showTitle="${fileName}"
				local showDir=""
				local seasonDir=""
				local season=""
				local matchVal=""
				
				matchVal="${fileType##*/}"										# get the matchVal passed back from sh_fileType
				
				if [[ "${matchVal}" =~ ([S][0-9]+) ]]; then						# need to use the if statement to get the season number from the matchVal
					season=${BASH_REMATCH[1]}									# get only SXX
					season=${season//[^0-9]/}									# get only the numbers, strip the 's' out
					season=$(echo ${season} | sed 's/^0*//') 					# remove leading zero's
				fi
				
				showTitle="${showTitle%${matchVal}*}"							# remove the matched value from the showTitle
				showTitle="${showTitle#*+}"										# remove any plus characters from the front of the string
				showTitle="${showTitle//_/ }"									# replace all underscores with spaces
				
				showTitle=$(echo ${showTitle} | awk '{print tolower($0)}') 											# lowercase the original text
				showTitle=$(echo ${showTitle} | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')		# capitalize the original text			
			
				showDir="${tvDir}/${showTitle}"									# create the show's title directory if it does not exist
				if [ ! -d "${showDir}" ]; then
			  		mkdir -p "${showDir}"
				fi
			
				seasonDir="${showDir}/Season ${season}"							# create the season directory if it does not exist
				if [ ! -d "${seasonDir}" ]; then
			  		mkdir -p "${seasonDir}"
				fi
		
				mv -f "${1}" "${seasonDir}"										# move the transcoded file to its final destination
			;;
			
			extra )
				local tempName="${fileName%%#*}"							 	# get the title
				tempName="${tempName#*+}"										# remove any plus characters from the front of the string
				tempName="${tempName//_/ }"										# replace all underscores with a space
				
				local labelInfo="${fileName#*#}"								# get the extras label
				local extrasType="${labelInfo%%-*}"								# get the extras type
				local extraTitle="${labelInfo#*-}"								# get the extras title
					
				tempName=$(echo ${tempName} | awk '{print tolower($0)}') 										# lowercase the original text
				tempName=$(echo ${tempName} | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text
				
				local movieFldrPath="${extMovePath}/${tempName}"
				if [ ! -d "${movieFldrPath}" ]; then							# create the movie titles directory
					mkdir -p "${movieFldrPath}"
				fi
			
				local extrasFldrPath="${movieFldrPath}/${extrasType}"		
				if [ ! -d "${extrasFldrPath}" ]; then							# create the extras directory
					mkdir -p "${extrasFldrPath}"
				fi				
			
				mv -f "${1}" "${extrasFldrPath}/${fileName}"					# move the transcoded file to its final destination
			;;
		
			special* )
				local tvDir="${extMovePath}"
				local showTitle="${fileName}"
				local showDir=""
				local seasonDir=""
				local season=""
				local matchVal=""
		
				matchVal="${fileType##*/}"										# get the matchVal passed back from sh_fileType
		
				if [[ "${matchVal}" =~ ([s][0]+) ]]; then						# need to use the if statement to get the season number from the matchVal
					season=${BASH_REMATCH[1]}									# get only SXX
					season=${season//[^0-9]/}									# get only the numbers, strip the 's' out
					season=$(echo ${season} | sed 's/^0*//') 					# remove leading zero's
				fi
		
				showTitle="${showTitle%${matchVal}*}"							# remove the matched value from the showTitle
				showTitle="${showTitle#*+}"										# remove any plus characters from the front of the string
				showTitle="${showTitle//_/ }"									# replace all underscores with spaces
				
				showTitle=$(echo ${showTitle} | awk '{print tolower($0)}') 										# lowercase the original text
				showTitle=$(echo ${showTitle} | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')	# capitalize the original text			
	
				showDir="${tvDir}/${showTitle}"									# create the show's title directory if it does not exist
				if [ ! -d "${showDir}" ]; then
			  		mkdir -p "${showDir}"
				fi
	
				seasonDir="${showDir}/Specials"									# create the specials directory if it does not exist
				if [ ! -d "${seasonDir}" ]; then
			  		mkdir -p "${seasonDir}"
				fi

				mv -f "${1}" "${seasonDir}"										# move the transcoded file to its final destination
			;;
		esac
	fi
}

function time_Stamp () {
	# ${1}: flag, "start" - start timer, "stop" - stop timer
	
	local timeStamp=""
	
	if [ "${1}" == "start" ]; then
																# set the start of the duration timer
		SECONDS=0
		
		timeStamp=$(date +"%r, %D")
		
		echo_Msg ""
		echo_Msg "Transcode started @ ${timeStamp}"
		echo_Msg "Files to be transcoded in this batch:"
		printf '%s\n' "${convertFiles[@]}"						# print to Terminal
		printf '%s\n' "${convertFiles[@]}"  2>&1 | logger -t batch.cmd
		
		if [ "${#convertFiles[@]}" == "1" ]; then
			. "${sh_sendNotification}" "Transcode Started" "${timeStamp}" "${#convertFiles[@]} file to convert"
			
		else
			. "${sh_sendNotification}" "Transcode Started" "${timeStamp}" "${#convertFiles[@]} files to convert"
		fi		
	else
		local duration=${SECONDS} 								# set the stop time

		local hours=$((${duration} / 3600))
		local minutes=$(((${duration} / 60) % 60))
		local seconds=$((${duration} % 60))
		
		if [ "${hours}" != "0" ];then
			if [ "${hours}" != "1" ]; then
				timeStamp="${hours} hours, "
			else
				timeStamp="${hours} hour, "
			fi	
		fi

		if [ "${minutes}" != "0" ]; then
			if [ "${minutes}" != "1" ]; then
				timeStamp=${timeStamp}"${minutes} minutes "
			else
				timeStamp=${timeStamp}"${minutes} minute "
			fi
		fi
		
		if [ "${seconds}" != "0" ]; then
			if [ "${seconds}" != "1" ]; then
				timeStamp=${timeStamp}"${seconds} seconds"
			else
				timeStamp=${timeStamp}"${seconds} second"
			fi
		fi
		
		echo_Msg ""
		echo_Msg "Transcode completed"
		echo_Msg "It took ${timeStamp}"
		echo_Msg "Files transcoded in this batch:"
		printf '%s\n' "${convertFiles[@]}"										# print to the Terminal
		printf '%s\n' "${convertFiles[@]}"  2>&1 | logger -t batch.cmd			# print to syslog
		
		if [ "${#convertFiles[@]}" == "1" ]; then
			. "${sh_sendNotification}" "Transcode Complete" "${convertFiles[0]##*/}" "converted in ${timeStamp}" "Hero"
		else
			. "${sh_sendNotification}" "Transcode Complete" "${#convertFiles[@]} files converted in ${timeStamp}" "" "Hero"
		fi
	fi	
}

function send_2Remote () {
	# ${1}: filePath
	
	local tempDir="${rsyncPath%/*}" 																					# get the path to /Transcode on the destination
	local upperLimit=3
	local sleepTime=10

	for ((i=1; i<=upperLimit; i++)); do
																														# rsync the file over to the Transcode destination
		rsync -a --info=progress2 --temp-dir="${tempDir}/" --delay-updates "${1}" sadmin@media.mdm2195.com:"${rsyncPath}"
																														# if an error occurred
		if [ "${?}" -ne "0" ]; then
			echo_Msg "Retrying rsync to ${rsyncPath} in ${sleepTime} seconds..."
			sleep ${sleepTime}																							# pause and try again
		else
			break																										# all good, we're done
		fi
	done
}

function transcode_Video () {
	local titleName=""
	local cropFile=""
	local cropOption=''
	local applyTag=""
	local subTitleOption=""
	local fileType=""
	local showTitle=""
	local renamedPath=""
	local hdbrkOption=''
	
	input="$(sed -n 1p "${queuePath}")"																				# get the first file to convert

	while [ "${input}" ]; do
	    titleName="$(basename "${input}" | sed 's/\.[^.]*$//')" 													# get the title of the video, no file extension
	    cropFile="${cropsDir}/${titleName}.txt"
	
		fileType="unknown"																							# file type is unknown
	
		if [[ "${titleName}" =~ ([Ss][0-9]+[Ee][0-9]+) ]]; then
			fileType="tvshow"																						# TV show
			applyTag=${tvTag}
			hdbrkOption="--handbrake-option decomb"
		else
			fileType="movie"																						# Movie
			applyTag=${movieTag}
			hdbrkOption=''
		fi
		
		if [[ "${input}" == *"+"* ]]; then																			# need to decomb this file
			hdbrkOption="--handbrake-option decomb"
		fi

	    if [ -f "${cropFile}" ]; then 																				# does the crop file exist
	        cropOption="--crop $(cat "${cropFile}")" 																# get the crop value
	    else
	        cropOption=''
	    fi

		local subTitleFile="${subsDir}/${titleName}.txt"															# get the title of the video, no file extension
		
	    if [ -f "${subTitleFile}" ]; then 																			# does the subtitle file exist
	        subTitleOption="--burn-subtitle $(cat "${subTitleFile}")" 												# get the subtitle file
	    else
	        subTitleOption=''
	    fi

	    sed -i '' 1d "${queuePath}" || exit 1  																		# delete the line from the queue file	
	
		echo_Msg "Transcoding ${input##*/}"
		. "${sh_sendNotification}" "Transcoding" "${input##*/}"
		
	    transcode-video ${outQualityOption} ${outDirOption} ${outExtOption} ${cropOption} ${subTitleOption} ${hdbrkOption} "${input}"	# transcode the file
		
		if [ "$fileType" == "tvshow" ]; then																		# TV Show
			if [[ "${renameFile}" == "auto" || "${renameFile}" == "tv" ]]; then
				showTitle=$(rename_File "${titleName}" "${tvShowFormat}" "TheTVDB")									# rename the file. For TV show: {Name} - {sXXeXX} - {Episode Name}.{ext}
			fi	
		else																										# movie
			if [[ "${renameFile}" == "auto" || "${renameFile}" == "movie" ]]; then
				showTitle=$(rename_File "${titleName}" "${movieFormat}")											# rename the file. For movie: {Name} {(Year of Release)}.{ext}
			fi
		fi
		
		renamedPath="${outDir}/${showTitle}"																		# renamed file with full path
														
		. "${sh_metadataTag}" "${renamedPath}" "title"																# set the file 'title' metadata
		
		renamedPath=$(move_Transcoded "${renamedPath}" "${plexPath}")												# move the transcoded file to final location if flag is set
		
		. "${sh_finderTag}" "${applyTag}" "${renamedPath}"															# set Finder tags after final move
		
		if [ ! -z "${sshUser}" ] && [ ! -z "${rsyncPath}" ] && [[ "${renamedPath}" != *@* ]]; then					# transfer completed files to a Transcode destination as long as they don't start with '@'
			send_2Remote "${renamedPath}"
		fi

		rm -f "${cropFile}"																							# remove the crop file
		
		input="$(sed -n 1p "${queuePath}")"																			# get the next file to process
	done	
}

function post_Processors () {
	echo_Msg "Moving log files to ${logDir}"
	find "${outDir}" -name '*.log' -exec mv {} "${logDir}" \;					# move all the log files to Logs
	
	if [ "${deleteWhenDone}" == "true" ]; then									# check the deleteWhenDone flag and proceed accordingly
		echo_Msg "Deleting originals"
		
		for i in "${convertFiles[@]}"; do
			rm -fr "${i}"														# remove all the original files
		done
	else
		echo_Msg "Moving originals to ${originalsDir}"
		
		for i in "${convertFiles[@]}"; do
			tag '--set' "${convertedTag}" "${i}"								# set the original file Finder tags to indicate it has been processed
			move_Original "${i}" "${originalsDir}"								# move all the original files to Originals									
		done
	fi
}

function clean_Up () {
																							# delete the semaphore file so processing can be started again
	rm -f "${workingPath}"
																							# process was halted, need to remove the last file and log that was not finished transcoding
	if [ ! -z "${input}" ]; then
		local titleName="$(basename "${input}" | sed 's/\.[^.]*$//')"
		titleName="${outDir}/${titleName}.${outExt}"
		rm -f "${titleName}"
		rm -f "${titleName}.log"
		
		. "${sh_sendNotification}" "Transcode Cancelled"
	fi
																							# remove the queue file
	if [ -e "${queuePath}" ]; then
	    rm -f "${queuePath}"
	fi
}

function __main__ () {
																											# exit if no files to convert
	if [ ${#convertFiles[@]} -gt 0 ] && [ "${convertFiles[0]}" == "${convertDir}/*" ]; then
		input=""
		echo_Msg ""
		echo_Msg "Exiting, no files found in ${convertDir} to transcode."
		
		. "${sh_sendNotification}" "Transcode Stopped" "No files to convert"

		exit 1
	fi	

	time_Stamp "start"																						# start the duration timer

	get_Prefs
	build_Resources
	pre_Processors 
	transcode_Video
	post_Processors

	time_Stamp "stop"																						# stop the duration timer
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap 'if_Error ${LINENO} $?' ERR															# trap errors
printf '\e[8;5;154t'																		# set the Terminal window size to 154x5

define_Constants

touch "${workingPath}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles
convertFiles=( "${convertDir}"/* )												   			# get a list of filenames with path to convert

__main__

exit 0