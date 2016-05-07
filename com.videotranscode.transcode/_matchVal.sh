#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_matchValTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_matchVal		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function extract_MatchVal () {
	# ${1}: filename w/wo file extension
	# Returns: matched value
	
	local matchVal=""
																# TV Show
	if [[ "${1}" =~ ([[:space:]]-[[:space:]]*([Ss][0-9]+[Ee][0-9]+)*-[Ee][0-9]+) ]]; then
		matchVal=${BASH_REMATCH[1]}				 				# get the matched text from the string SXXEYYEZZ
	elif [[ "${1}" =~ ([[:space:]]-[[:space:]]*([Ss][0-9]+[Ee][0-9]+)) ]]; then
		matchVal=${BASH_REMATCH[1]}								# get the matched text from the string SXXEYY
	elif [[ "${1}" =~ ([[:space:]]*[(][0-9]+[)]) ]]; then
		matchVal=${BASH_REMATCH[1]}		 						# get the matched text from the string (YEAR)
	fi
	
	echo "${matchVal}"
}

function __main__ () {
	extract_MatchVal "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.1, 04-10-2016

__main__ "${@}"