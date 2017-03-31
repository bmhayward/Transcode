#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_workDirTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_workDir		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __get_DirFrom_plist__ () {
	# ${1}: path to the plist file
	
	local plstBuddy=""
	local tmpConvertDir=""
	
	plstBuddy="/usr/libexec/PlistBuddy"
	
	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") path to the plist file not passed, exiting..."
	    exit 1
	fi
	
	if [[ -e "${1}" ]]; then
		tmpConvertDir=$(${plstBuddy} -c 'print :WatchPaths:0' "${1}")

		readonly CONVERTDIR="${tmpConvertDir}"												# get the path to /Convert or /Ingest
		readonly WORKDIR="${CONVERTDIR%/*}"													# get the path to /Transcode or /root
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.1.0, 02-06-2017

__get_DirFrom_plist__ "${@}"