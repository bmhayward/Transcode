#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_moveOriginalTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_moveOriginal	
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __moveOriginal__ () {
	# ${1}: path of file to move with filename and extension
	# ${2}: external move location
	
	if [[ $# -lt 2 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") path of file to move with filename and extension, and external move location not passed, exiting..."
	    exit 1
	fi
	
	local fileName=""
	local extMovePath=""
	local fileType=""
	local movieFldrPath=""
	
	fileName="${1##*/}"
	extMovePath="${2}"
			
	fileType=$(. "_fileType.sh" "${1}")														# get the type of file, movie, tv show, multi episode, extra, skip
	
	. "_echoMsg.sh" "Move original file type: ${fileType}" ""
																							# custom path, not skipping
	if [[ -n "${extMovePath}" ]]; then
		 																					# what file type
		case "${fileType}" in
			skip )				
				mv -f "${1}" "${extMovePath}"												# move the transcoded file to its final destination
			;;

			movie )
				local movieTitle=""
				
				movieTitle="${fileName%_*}"													# get the title without extension
				movieTitle="${movieTitle#+}"												# remove leading plus characters
				movieTitle="${movieTitle//_/ }"												# replace all underscores with spaces
				
				movieTitle=$(echo "${movieTitle}" | awk '{print tolower($0)}') 				# lowercase the original text
																							# capitalize the original text
				movieTitle=$(echo "${movieTitle}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
				
				movieFldrPath="${extMovePath}/${movieTitle}"								# create the movie titles directory
				
				if [[ ! -d "${movieFldrPath}" ]]; then
					mkdir -p "${movieFldrPath}"
				fi
				
				mv -f "${1}" "${movieFldrPath}"												# move the original file to its final destination
			;;
				
			tvshow*|multi* )
				local tvDir="${extMovePath}"
				local showTitle="${fileName}"
				local showDir=""
				local seasonDir=""
				local season=""
				local matchVal=""
				
				matchVal="${fileType##*/}"													# get the matchVal passed back from sh_fileType
				if [[ "${matchVal}" =~ ([S][0-9]+) ]]; then									# need to use the if statement to get the season number from the matchVal
					season=${BASH_REMATCH[1]}												# get only SXX
					season=${season//[^0-9]/}												# get only the numbers, strip the 's' out
					season=$(echo "${season}" | sed 's/^0*//') 								# remove leading zero's
				fi
				
				showTitle="${showTitle%${matchVal}*}"										# remove the matched value from the showTitle
				showTitle="${showTitle#+}"													# remove leading plus characters
				showTitle="${showTitle//_/ }"												# replace all underscores with spaces
				
				showTitle=$(echo "${showTitle}" | awk '{print tolower($0)}') 				# lowercase the original text
																							# capitalize the original text
				showTitle=$(echo "${showTitle}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')		
			
				showDir="${tvDir}/${showTitle}"												# create the show's title directory if it does not exist
				if [[ ! -d "${showDir}" ]]; then
			  		mkdir -p "${showDir}"
				fi
			
				seasonDir="${showDir}/Season ${season}"										# create the season directory if it does not exist
				if [[ ! -d "${seasonDir}" ]]; then
			  		mkdir -p "${seasonDir}"
				fi
		
				mv -f "${1}" "${seasonDir}"													# move the transcoded file to its final destination
			;;
			
			extra )
				local tempName=""
				local labelInfo=""
				local extrasType=""
				local extrasFldrPath=""

				tempName="${fileName%'%'*}"							 						# get the title

				labelInfo="${fileName#*%}"													# get the extras label
				
				if [[ ${fileName} == *"#"* ]]; then											# legacy tag
					tempName="${fileName%%#*}"								 				# get the title

					labelInfo="${fileName#*#}"												# get the extras label
				fi

				tempName="${tempName#*+}"													# remove any plus characters from the front of the string
				tempName="${tempName//_/ }"													# replace all underscores with a space

				extrasType="${labelInfo%%-*}"												# get the extras type
					
				tempName=$(echo "${tempName}" | awk '{print tolower($0)}') 					# lowercase the original text
																							# capitalize the original text
				tempName=$(echo "${tempName}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
				
				movieFldrPath="${extMovePath}/${tempName}"
				if [[ ! -d "${movieFldrPath}" ]]; then										# create the movie titles directory
					mkdir -p "${movieFldrPath}"
				fi
			
				extrasFldrPath="${movieFldrPath}/${extrasType}"		
				if [[ ! -d "${extrasFldrPath}" ]]; then										# create the extras directory
					mkdir -p "${extrasFldrPath}"
				fi				
			
				mv -f "${1}" "${extrasFldrPath}/${fileName}"								# move the transcoded file to its final destination
			;;
		
			special* )
				local tvDir="${extMovePath}"
				local showTitle="${fileName}"
				local showDir=""
				local seasonDir=""
				local season=""
				local matchVal=""
		
				matchVal="${fileType##*/}"													# get the matchVal passed back from sh_fileType
		
				if [[ "${matchVal}" =~ ([s][0]+) ]]; then									# need to use the if statement to get the season number from the matchVal
					season=${BASH_REMATCH[1]}												# get only SXX
					season=${season//[^0-9]/}												# get only the numbers, strip the 's' out
					season=$(echo "${season}" | sed 's/^0*//') 								# remove leading zero's
				fi
		
				showTitle="${showTitle%${matchVal}*}"										# remove the matched value from the showTitle
				showTitle="${showTitle#*+}"													# remove any plus characters from the front of the string
				showTitle="${showTitle//_/ }"												# replace all underscores with spaces
				
				showTitle=$(echo "${showTitle}" | awk '{print tolower($0)}') 				# lowercase the original text
																							# capitalize the original text
				showTitle=$(echo "${showTitle}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')		
	
				showDir="${tvDir}/${showTitle}"												# create the show's title directory if it does not exist
				if [[ ! -d "${showDir}" ]]; then
			  		mkdir -p "${showDir}"
				fi
	
				seasonDir="${showDir}/Specials"												# create the specials directory if it does not exist
				if [[ ! -d "${seasonDir}" ]]; then
			  		mkdir -p "${seasonDir}"
				fi

				mv -f "${1}" "${seasonDir}"													# move the transcoded file to its final destination
			;;
		esac
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.9, 02-04-2017

__moveOriginal__ "${@}"