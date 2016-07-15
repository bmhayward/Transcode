#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_echoMsgTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_echoMsg		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	# loggerTag is defined as global in the calling script
	
	local lightBlue='\033[0;36m'
	local lightBlueBold='\033[1;36m'
	local lightGreen='\033[0;32m'
	local lightGreenBold='\033[1;32m'
	local lightYellow='\033[0;93m'
	local lightYellowBold='\033[1;93m'
	local lightMagenta='\033[0;95m'
	local lightMagentaBold='\033[1;95m'
	local whiteBold='\033[1;37m'
	local redPlain='\033[0;91m'
	local redBold='\033[1;91m'
	local noColor='\033[0m'
	local msgTxt=""
	
	if [ $# -eq 1 ]; then
		printf "${1}\n"											# echo to the Terminal
	fi
	
	msgTxt="${1}"
	
	if [[ "${1}" = *"${lightBlue:4}"* || "${1}" = *"${lightGreen:4}"* || "${1}" = *"${lightYellow:4}"* || "${1}" = *"${whiteBold:4}"* || "${1}" = *"${redPlain:4}"* || "${1}" = *"${noColor:4}"* || "${1}" = *"${lightBlueBold:4}"* || "${1}" = *"${lightGreenBold:4}"* || "${1}" = *"${lightYellowBold:4}"* || "${1}" = *"${redBold:4}"* || "${1}" = *"${lightMagenta:4}"* || "${1}" = *"${lightMagentaBold:4}"* ]]; then
		msgTxt="${1#*m}"										# strip out any color code tags
		msgTxt="${msgTxt%[*}"
	fi
	
    printf "${msgTxt}\n" 2>&1 | logger -t "${loggerTag}"		# echo to syslog
}

function __main__ () {
	echo_Msg "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.2, 07-10-2016

__main__ "${@}"