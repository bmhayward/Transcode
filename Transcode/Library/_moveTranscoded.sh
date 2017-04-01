#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_moveTranscodedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_moveTranscoded
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __moveTranscoded__ () {
	# ${1}: path of file to move with filename and extension
	# ${2}: external move location
	# ${3}: movieFormat
	# ${4}: tvShowFormat
	# Returns: moved path to the file
	
	if [[ $# -lt 4 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") path of file to move with filename and extension, external move location, movieFormat, tvShowFormat not passed, exiting..."
	    exit 1
	fi
	
	local movedPath=""
	local fileName=""
	local tempFileName=""
	local extMovePath=""
	local fileType=""
	local movieFldrPath=""
	local movieFormat=""
	local tvShowFormat=""
	
	movedPath="${1}"
	fileName="${1##*/}"
	extMovePath="${2}"
	movieFormat="${3}"
	tvShowFormat="${4}"
		
	fileType=$(. "_fileType.sh" "${movedPath}")												# get the type of file, movie, tv show, multi episode, extra, skip
	
	. "_echoMsg.sh" "Move transcoded file type: ${fileType}" ""
																							# custom path, not skipping
	if [[ -n "${extMovePath}" ]]; then
		 																					# what file type
		case "${fileType}" in
			skip )
				. "_echoMsg.sh" "Move transcoded file: nothing to see here, skipping move" ""
			;;

			movie )
				local moviesDir=""
				
				if [[ -z "${movieFormat}" ]]; then											# the movie format has not been changed
					moviesDir="${extMovePath}/Movies"
					if [[ ! -d "${moviesDir}" ]]; then										# create the Movies directory
				  		mkdir -p "${moviesDir}"
					fi
																							# remove quality setting value if present
					tempFileName="${fileName%.--*}"
					
					movieFldrPath="${moviesDir}/${tempFileName%.*}"							# create the movie titles directory
					if [[ ! -d "${movieFldrPath}" ]]; then
						mkdir -p "${movieFldrPath}"
					fi
					
					mv -f "${1}" "${movieFldrPath}"											# move the transcoded file to its final destination
				
					movedPath="${movieFldrPath}/${fileName}"
				fi
			;;
				
			tvshow*|multi* )
			 																				# TV Show format has not been changed from the default
				if [[ "${tvShowFormat}" == "{n} - {'s'+s.pad(2)}e{e.pad(2)} - {t}" ]]; then
					local tvDir="${extMovePath}/TV Shows"
					local showTitle="${fileName}"
					local showDir=""
					local seasonDir=""
					local season=""
					local matchVal=""
					
					matchVal="${fileType##*/}"												# get the matchVal passed back from sh_fileType
					
					if [[ "${matchVal}" =~ ([s][0-9]+) ]]; then								# need to use the if statement to get the season number from the matchVal
						season=${BASH_REMATCH[1]}											# get only SXX
						season=${season//[^0-9]/}											# get only the numbers, strip the 's' out
						season=$(echo "${season}" | sed 's/^0*//') 							# remove leading zero's
					fi
					
					showTitle="${showTitle%${matchVal}*}"									# remove the matched value from the showTitle
					showTitle="${showTitle% - *}"				
				
					if [[ ! -d "${tvDir}" ]]; then											# create the TV Show directory if it does not exist
				  		mkdir -p "${tvDir}"
					fi
				
					showDir="${tvDir}/${showTitle}"											# create the show's title directory if it does not exist
					if [[ ! -d "${showDir}" ]]; then
				  		mkdir -p "${showDir}"
					fi
				
					seasonDir="${showDir}/Season ${season}"									# create the season directory if it does not exist
					if [[ ! -d "${seasonDir}" ]]; then
				  		mkdir -p "${seasonDir}"
					fi
			
					mv -f "${1}" "${seasonDir}"												# move the transcoded file to its final destination
				
					movedPath="${seasonDir}/${fileName}"
				fi
			;;
			
			extra )
				local tempName=""
				local labelInfo=""
				local extrasType=""
				local extraTitle=""
				local extrasFldrPath=

				tempName="${fileName%'%'*}"							 						# get the title

				labelInfo="${fileName#*%}"													# get the extras label

				if [[ ${fileName} == *"#"* ]]; then											# legacy tag
					tempName="${fileName%%#*}"								 				# get the title

					labelInfo="${fileName#*#}"												# get the extras label
				fi

				extrasType="${labelInfo%%-*}"												# get the extras type
				extraTitle="${labelInfo#*-}"												# get the extras title

				if [[ -z "${movieFormat}" ]]; then											# the movie format has not been changed
					local moviesDir="${extMovePath}/Movies"
					if [[ ! -d "${moviesDir}" ]]; then										# create the Movies directory
				  		mkdir -p "${moviesDir}"
					fi

					movieFldrPath="${moviesDir}/${tempName}"
					if [[ ! -d "${movieFldrPath}" ]]; then									# create the movie titles directory
						mkdir -p "${movieFldrPath}"
					fi

					extrasFldrPath="${movieFldrPath}/${extrasType}"		
					if [[ ! -d "${extrasFldrPath}" ]]; then									# create the extras directory
						mkdir -p "${extrasFldrPath}"
					fi				

					mv -f "${1}" "${extrasFldrPath}/${extraTitle}"							# move the transcoded file to its final destination

					movedPath="${extrasFldrPath}/${extraTitle}"
				fi
			;;
		
			special* )
																							# TV Show format has not been changed
				if [[ "${tvShowFormat}" == "{n} - {'s'+s.pad(2)}e{e.pad(2)} - {t}" ]]; then
					local tvDir="${extMovePath}/TV Shows"
					local showTitle="${fileName}"
					local showDir=""
					local seasonDir=""
					local season=""
					local matchVal=""
			
					matchVal="${fileType##*/}"												# get the matchVal passed back from sh_fileType
			
					if [[ "${matchVal}" =~ ([s][0]+) ]]; then								# need to use the if statement to get the season number from the matchVal
						season=${BASH_REMATCH[1]}											# get only SXX
						season=${season//[^0-9]/}											# get only the numbers, strip the 's' out
						season=$(echo "${season}" | sed 's/^0*//') 							# remove leading zero's
					fi
			
					showTitle="${showTitle%${matchVal}*}"									# remove the matched value from the showTitle
					showTitle="${showTitle% - *}"				
		
					if [[ ! -d "${tvDir}" ]]; then											# create the TV Show directory if it does not exist
				  		mkdir -p "${tvDir}"
					fi
		
					showDir="${tvDir}/${showTitle}"											# create the show's title directory if it does not exist
					if [[ ! -d "${showDir}" ]]; then
				  		mkdir -p "${showDir}"
					fi
		
					seasonDir="${showDir}/Specials"											# create the specials directory if it does not exist
					if [[ ! -d "${seasonDir}" ]]; then
				  		mkdir -p "${seasonDir}"
					fi
	
					mv -f "${1}" "${seasonDir}"												# move the transcoded file to its final destination
		
					movedPath="${seasonDir}/${fileName}"
				fi
			;;
		esac
	fi
	
	echo "${movedPath}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.1.0, 03-18-2016

__moveTranscoded__ "${@}"