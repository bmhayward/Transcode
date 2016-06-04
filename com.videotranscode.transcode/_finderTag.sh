#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_finderTagTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_finderTag		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function set_FinderTag () {
	# ${1}: tag information
	# ${2}: path to the file
	
	local tag2Apply="${1}"

	if [ "${2##*.}" != "mkv" ]; then
		case "${2}" in							# if this is an Extra, change the tagging based on the preference setting
			*"Featurettes"*|*"Behind The Scenes"*|*"Deleted Scenes"*|*"Interviews"*|*"Scenes"*|*"Shorts"*|*"Trailers"*|*"Specials"*|*"s00"* )
				tag2Apply="${extrasTag}"
			;;
		esac
	fi
	
	tag --set "${tag2Apply}" "${2}"			# set Finder tags
}

function __main__ () {
	set_FinderTag "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.3, 06-04-2016

__main__ "${@}"