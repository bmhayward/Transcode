#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/batch_rsyncTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_rsync		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a wrapper to Don Melton's batch script which transcodes DVD and Blu-Ray content.
#	https://github.com/donmelton/video_transcoding
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.8, 05-23-2016"
	
	loggerTag="batch.rsync"
		
	readonly outDir="${convertDir}"
	
	readonly queuePath="${workDir}/queue_remote.txt"						# workDir is global, from watchFolder_rsync
	readonly prefPath="${workDir}/Prefs.txt"
	readonly workingPath="${libDir}/Preferences/${workingPlist}"			# workingPlist is global, from watchFolder_rsync
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_matchVal="${appScriptsPath}/_matchVal.sh"
	readonly sh_sendNotification="${appScriptsPath}/_sendNotification.sh"
	readonly sh_fileType="${appScriptsPath}/_fileType.sh"
	readonly sh_metadataTag="${appScriptsPath}/_metadataTag.sh"
	readonly sh_finderTag="${appScriptsPath}/_finderTag.sh"
	readonly sh_readPrefs="${appScriptsPath}/_readPrefs.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	
	# From watchFolder_rsync.sh:
		# readonly convertDir="${workDir}/Remote"
		# readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")
		# readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"	
}

function read_Prefs () {
	if [ -e "${prefPath}" ]; then
		. "${sh_readPrefs}" "${prefPath}"											# read in the preferences from Prefs.txt
	else
		. "${sh_echoMsg}" "Pref.txt is missing, exiting..."
		exit 1
	fi
}

function pre_Processors () {
	. "${sh_echoMsg}" "Pre-processing files"
	local fileNameExt=""
	local queueValue=""
	
	for i in "${convertFiles[@]}"; do
		if [ ! -d "${i}" ]; then
			fileNameExt=${i##*/}										# filename with extension

			queueValue="${convertDir}/${fileNameExt}"
			echo ${queueValue} >> "${queuePath}"						# write the file path to the queue file
		fi
	done
}

function move_Transcoded () {
	# ${1}: path of file to move with filename and extension
	# ${2}: filename with extension
	# Returns: moved path to the file
	
	local movedPath="${1}"
	local fileType=""
	
	fileType=$(. "${sh_fileType}" "${movedPath}")								# get the type of file, movie, tv show, multi episode, extra, skip
	
	. "${sh_echoMsg}" "Moving: File type is ${fileType}" ""
																				# custom path
	if [ -n "${plexPath}" ]; then
		 																		# what file type
		case "${fileType}" in
			skip )
				. "${sh_echoMsg}" "Moving: nothing to see here, skipping move" ""
			;;
			
			movie )
				if [ -z "${movieFormat}" ]; then								# the movie format has not been changed
					local moviesDir="${plexPath}/Movies"
					if [ ! -d "${moviesDir}" ]; then							# create the Movies directory
				  		mkdir -p "${moviesDir}"
					fi
					
					local movieFldrPath="${moviesDir}/${2%.*}"					# create the movie titles directory
					if [ ! -d "${movieFldrPath}" ]; then
						mkdir -p "${movieFldrPath}"
					fi
					
					mv -f "${1}" "${movieFldrPath}"								# move the transcoded file to its final destination
				
					movedPath="${movieFldrPath}/${2}"
				fi
			;;
				
			tvshow*|multi* )
				if [ "${tvShowFormat}" == "{n} - {'s'+s.pad(2)}e{e.pad(2)} - {t}" ]; then 	# TV Show format has not been changed
					local tvDir="${plexPath}/TV Shows"
					local showTitle="${2}"
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
				
					movedPath="${seasonDir}/${1##*/}"
				fi
			;;
			
		extra )
			local tempName="${2%%#*}"												# get the title
			local labelInfo="${2#*#}"												# get the extras label
			local extrasType="${labelInfo%%-*}"										# get the extras type
			local extraTitle="${labelInfo#*-}"										# get the extras title
		
			if [ -z "${movieFormat}" ]; then										# the movie format has not been changed
				local moviesDir="${plexPath}/Movies"
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
				local tvDir="${plexPath}/TV Shows"
				local showTitle="${2}"
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
		
				movedPath="${seasonDir}/${1##*/}"
			fi
		;;
		esac
	fi
	
	echo "${movedPath}"
}

function rsync_Process () {
	local titleName=""
	local applyTag=""
	local fileType=""
	local showTitle=""
	local renamedPath=""
	
	input="$(sed -n 1p "${queuePath}")"																	# get the first file to convert

	while [ "${input}" ]; do
	    titleName="$(basename "${input}" | sed 's/\.[^.]*$//')" 										# get the title of the video, no file extension
		showTitle="${input##*/}"																		# get the title of the video including extension
	    fileType="unknown"																				# file type is unknown
	    
		. "${sh_echoMsg}" "Processing remote title ${showTitle}"
		
	    if [[ "${titleName}" =~ ([s][0-9]+[e][0-9]+) ]]; then
   			fileType="tvshow"																			# TV show
   			applyTag=${tvTag}
   		else
   			fileType="movie"																			# Movie
   			applyTag=${movieTag}
   		fi

		. "${sh_echoMsg}" "${showTitle} file type: ${fileType}"

	 	sed -i '' 1d "${queuePath}" || exit 1  															# delete the line from the queue file
	   		
		renamedPath="${outDir}/${showTitle}"															# renamed file with full path
											
		. "${sh_metadataTag}" "${renamedPath}" "title" "${showTitle}"									# set the file 'title' metadata
		
		renamedPath=$(move_Transcoded "${renamedPath}" "${showTitle}")									# move the transcoded file to final location if flag is set
		
		. "${sh_echoMsg}" "Moved ${showTitle} to ${renamedPath}"
		
		. "${sh_finderTag}" "${applyTag}" "${renamedPath}"												# set Finder tags after final move
		
		input="$(sed -n 1p "${queuePath}")"																# get the next file to process
	done	
}

function clean_Up () {
																							# delete the semaphore file so processing can be started again
	rm -f "${workingPath}"
																							# process was halted, need to remove the last file and log that was not finished transcoding
	if [ ! -z "${input}" ]; then		
		. "${sh_sendNotification}" "Processing Cancelled"
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
		. "${sh_echoMsg}" ""
		. "${sh_echoMsg}" "Exiting, no files found in ${convertDir} to process."

		exit 1
	fi	

	read_Prefs
	pre_Processors
	rsync_Process
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
ttrap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

define_Constants

touch "${workingPath}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles
convertFiles=( "${convertDir}"/* )												   			# get a list of filenames with path to convert

__main__

exit 0