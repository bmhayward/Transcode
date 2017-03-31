#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_matchValTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_matchVal		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function extract_MatchVal () {
	# ${1}: filename w/wo file extension
	# Returns: matched value
	
	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") filename w/wo file extension not passed, exiting..."
	    exit 1
	fi
	
	local matchVal=""
																							# TV Show
	if [[ "${1}" =~ ([[:space:]]-[[:space:]]*([Ss][0-9]+[Ee][0-9]+)*-[Ee][0-9]+) ]]; then
		matchVal=${BASH_REMATCH[1]}				 											# get the matched text from the string SXXEYYEZZ
	elif [[ "${1}" =~ ([[:space:]]-[[:space:]]*([Ss][0-9]+[Ee][0-9]+)) ]]; then
		matchVal=${BASH_REMATCH[1]}															# get the matched text from the string SXXEYY
	elif [[ "${1}" =~ ([[:space:]]*[(][0-9]+[)]) ]]; then
		matchVal=${BASH_REMATCH[1]}		 													# get the matched text from the string (YEAR)
	fi
	
	echo "${matchVal}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.7, 02-04-2017

extract_MatchVal "${@}"