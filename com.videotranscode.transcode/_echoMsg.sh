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
	
	if [ $# -eq 1 ]; then
		echo "${1}"											# echo to the Terminal
	fi
	
    echo "${1}" 2>&1 | logger -t "${loggerTag}"				# echo to syslog
}

function __main__ () {
	echo_Msg "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.0, 05-19-2016

__main__ "${@}"