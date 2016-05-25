#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/tmp/_ifErrorTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_ifError		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function if_Error () {
	# ${1}: last line of error occurrence
	# ${2}: error code of last command

	local lastLine="${1}"
	local lastErr="${2}"
	local currentScript=$(basename -- "${0}")
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

function __main__ () {
	if_Error "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.0, 05-23-2016

__main__ "${@}"