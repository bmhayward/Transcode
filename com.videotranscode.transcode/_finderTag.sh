#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_finderTagTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_finderTag
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function set_FinderTag () {
	# ${1}: tag information
	# ${2}: path to the file
	# ${3}: optional, extrasTag
	#	${PREFPATH}: global, set by calling function
	#	${loggerTag}: global, set by calling function
	
	if [[ $# -lt 2 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") tag2Apply or path to the file not passed, exiting..."
    	exit 1
	fi
	
	local tag2Apply=""
	local extraTag=""
	local tagOption=""
	
	tag2Apply="${1}"
	tagOption="--set"
	
	if [[ "${tag2Apply}" == *"|"* ]]; then
		tagOption="--add"
																							# strip out the |
		tag2Apply="${tag2Apply%|}"
	fi
		
	if [[ $# -eq 3 ]]; then
		extraTag="${3}"
	else
		extraTag=$(. "_readPrefs.sh" "${PREFPATH}" "ExtrasTags")
	fi
	
	if [[ "${2##*.}" != "mkv" ]] && [[ "${2##*.}" != "log" ]]; then
		case "${2}" in																		# if this is an Extra, change the tagging based on the preference setting
			*"Featurettes"*|*"Behind The Scenes"*|*"Deleted Scenes"*|*"Interviews"*|*"Scenes"*|*"Shorts"*|*"Trailers"*|*"Specials"*|*"s00"* )
			if [[ "${1}" == *"--"* ]]; then
																							# make sure to get the video quality setting if it exists
				extraTag="${extraTag},--${1##*-}"
			fi
				tag2Apply="${extraTag}"
			;;
		esac
	fi
																							# set Finder tags
	tag "${tagOption}" "${tag2Apply}" "${2}"	2>&1 | logger -t "${loggerTag}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.1.3, 03-13-2017

set_FinderTag "${@}"