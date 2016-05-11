#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_readPrefsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_readPrefs		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function read_Prefs () {
																				# create the default preferences file if it does not exist			
	declare -a prefs

	let i=0
	while IFS='' read -r lineData || [[ -n "${lineData}" ]]; do					# read in the preferences from the prefs file
	    prefs[i]="${lineData}"
	    ((++i))
	done < "${1}"

	readonly outExt="${prefs[0]}"												# get the transcode file extension
	
	if [ "${outExt}" == "mkv" ]; then
		readonly outExtOption=""		
	else
		readonly outExtOption="--${outExt}"
	fi
	
	readonly deleteWhenDone="${prefs[1]}"										# what to do with the original files when done
	readonly movieTag="${prefs[2]}"												# Finder tags for movie files
	readonly tvTag="${prefs[3]}"												# Finder tags for TV show files
	readonly convertedTag="${prefs[4]}"											# Finder tags for original files that have been transcoded
	readonly renameFile="${prefs[5]}"											# whether or not to auto-rename files
	readonly movieFormat="${prefs[6]}"											# movie rename format
	readonly tvShowFormat="${prefs[7]}"											# TV show rename format
	readonly plexPath="${prefs[8]}"												# where to put the transcoded files in Plex
	readonly sshUser="${prefs[9]}"												# get the ssh username
	readonly rsyncPath="${prefs[10]}"											# get the path to the rsync Remote directory
	readonly ingestPath="${prefs[11]}"											# get the path to the ingest directory
	readonly extrasTag="${prefs[12]}"											# Finder tags for Extra show files
	readonly outQuality="${prefs[13]}"											# Output quality setting to use
	readonly tlaApp="${prefs[14]}"												# Transcode Log Analyzer helper app
	
	if [ "${tlaApp##*.}" = "app" ]; then
		readonly tlaHelper="${tlaApp}"
	else
		readonly tlaHelper="${tlaApp}.app"
	fi
	
	if [ -z "${outQuality}" ]; then
		readonly outQualityOption=""		
	else
		readonly outQualityOption="--${outExt}"
	fi
}

function __main__ () {
	read_Prefs "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.2, 05-10-2016

__main__ "${@}"