#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_metadataTagTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_metadataTag		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function set_MetadataTag () {
	# ${1}: file path
	# ${2}: metadata tag

	local metaVal=${1##*/}
	local matchVal=$(. "${sh_matchVal}" "${metaVal}") 			# get the string to strip out

	metaVal=${metaVal%${matchVal}*}								# remove the matched value from the metaVal
	
	atomicparsley "${1}" --overWrite --${2} "${metaVal}"		# set the metadata tag
}

function __main__ () {
	set_MetadataTag "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.1, 04-14-2016

__main__ "${@}"