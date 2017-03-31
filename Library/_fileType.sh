#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_fileTypeTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_fileType		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function file_Type () {
	# ${1}: name of title with or without extension
	# Returns: type of file; movie, tvshow, multi/sXXeYYeZZ, extra, skip
	
	local matchVal=""
	local fileType=""
	
	fileType="movie"
	
	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") name of title not passed, exiting..."
    	exit 1
	fi

	case "${1}" in
		*@* | *title* | *^* )
			fileType="skip"
		;;
		
		*"Featurettes"*|*"Behind The Scenes"*|*"Deleted Scenes"*|*"Interviews"*|*"Scenes"*|*"Shorts"*|*"Trailers"* )
			fileType="extra"
		;;
		
		* )
			if [[ "${1}" =~ ([Ss][0-9]+[Ee][0-9]+[Ee][0-9]+) ]]; then						# TV multi-episode sXXeYYeZZ
				matchVal=${BASH_REMATCH[1]}
				fileType="multi/${matchVal}"
			elif [[ "${1}" =~ ([Ss][0][0][Ee][0-9]+) ]]; then								# TV special s00eYY
				matchVal=${BASH_REMATCH[1]}
				fileType="special/${matchVal}"
			elif [[ "${1}" =~ ([Ss][0-9]+[Ee][0-9]+) ]]; then								# TV episode sXXeYY
				matchVal=${BASH_REMATCH[1]}
				fileType="tvshow/${matchVal}"
			fi
		;;
	esac

	echo "${fileType}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.9, 02-04-2017

file_Type "${@}"
