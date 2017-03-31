#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_trimStringTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_trimString
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __trim__ () {
	# ${1}: variable to trim spaces from
	# Returns: variable with spaces removed from the front and back
	
	local var=""
	
	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") variable to trim spaces from not passed, exiting..."
	    exit 1
	fi
	
    var="$*"

    var="${var#"${var%%[![:space:]]*}"}"   													# remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   													# remove trailing whitespace characters

    echo "${var}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.4, 02-04-2016

__trim__ "${@}"