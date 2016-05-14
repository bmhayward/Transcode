#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_fileTypeTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_fileType		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function file_Type () {
	# ${1}: name of title with or without extension
	# Returns: type of file; movie, tvshow, multi/sXXeYYeZZ, extra, skip
	
	local matchVal=""
	local fileType="movie"
	
	case "${1}" in
		*@* | *title* | *^* )
			fileType="skip"
		;;
		*"Featurettes"*|*"Behind The Scenes"*|*"Deleted Scenes"*|*"Interviews"*|*"Scenes"*|*"Shorts"*|*"Trailers"* )
			fileType="extra"
		;;
		* )
			if [[ "${1}" =~ ([Ss][0-9]+[Ee][0-9]+[Ee][0-9]+) ]]; then
				matchVal=${BASH_REMATCH[1]}
				fileType="multi/${matchVal}"
			elif [[ "${1}" =~ ([Ss][0][0][Ee][0-9]+) ]]; then
				matchVal=${BASH_REMATCH[1]}
				fileType="special/${matchVal}"
			elif [[ "${1}" =~ ([Ss][0-9]+[Ee][0-9]+) ]]; then
				matchVal=${BASH_REMATCH[1]}
				fileType="tvshow/${matchVal}"
			fi
		;;
	esac

	echo "${fileType}"
}

function __main__ () {
	file_Type "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.4, 05-13-2016

__main__ "${@}"