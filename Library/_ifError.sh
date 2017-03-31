#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/tmp/_ifErrorTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_ifError		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __if_Error__ () {
	# ${1}: last line of error occurrence
	# ${2}: error code of last command

	local lastLine=""
	local lastErr=""
	local currentScript=""
	
	lastLine="${1}"
	lastErr="${2}"
	currentScript=$(basename -- "${0}")
																							# if lastErr > 0 then echo error msg and log
	if [[ ${lastErr} -gt 0 ]]; then
		echo 2>&1 | logger -t "${loggerTag}"
		echo ""
		echo "${currentScript}: "$'\e[91m'"Something went awry :-("
		echo "${currentScript}: Something went awry :-(" 2>&1 | logger -t "${loggerTag}"
		echo "Script error encountered on $(date): Line: ${lastLine}: Exit status of last command: ${lastErr}"
		echo "Script error encountered on $(date): Line: ${lastLine}: Exit status of last command: ${lastErr}" 2>&1 | logger -t "${loggerTag}"
		echo "Exiting..."
		echo $'\e[0m'
		echo "Exiting..." 2>&1 | logger -t "${loggerTag}"

		exit 1
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.3, 02-07-2017

__if_Error__ "${@}"