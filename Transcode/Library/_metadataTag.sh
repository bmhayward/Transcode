#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_metadataTagTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_metadataTag		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function set_MetadataTag () {
	# ${1}: file path
	# ${2}: metadata tag
	#	${loggerTag}: global, set by calling function

	local metaVal=""
	local matchVal=""
	
	if [[ $# -lt 2 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") metaVal or matchVal not passed, exiting..."
    	exit 1
	fi
	
	metaVal=${1##*/}
	matchVal=$(. "_matchVal.sh" "${metaVal}") 												# get the string to strip out
	

	metaVal=${metaVal%${matchVal}*}															# remove the matched value from the metaVal
																							# set the metadata tag
	atomicparsley "${1}" --overWrite "--${2}" "${metaVal}" 2>&1 | logger -t "${loggerTag}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.1.0, 02-04-2017

set_MetadataTag "${@}"
