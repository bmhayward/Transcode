#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/transcode_ReadPrefsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	transcode_ReadPrefs
#	Copyright (c) 2017 Brent Hayward
#
#	
#	This script sets the prefs.plist values for Transcode
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------


function define_Constants () {
	local versStamp="Version 1.0.4, 03-23-2017"
	
	loggerTag="transcode.prefs"
		
	readonly LIBDIR="${HOME}/Library"
	readonly PLISTBUDDY="/usr/libexec/PlistBuddy"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# get the path to the Transcode folder, returns the WORKDIR and CONVERTDIR variable
	
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
	
	returnPrefValues=""
}

function get_Prefs () {
																							# create the default preferences file if it does not exist
	if [[ ! -e "${PREFPATH}" ]]; then
	   . "_writePrefs.sh" "${PREFPATH}"
	fi
	
	. "_readPrefs.sh" "${PREFPATH}"															# read in the preferences from prefs.plist
}

function convert_Prefs2Str () {
	local i=0
	
	declare -a convertPrefs_a
	
	convertPrefs_a[0]="${outExt_}"															# get the output file extension
	convertPrefs_a[1]="${deleteWhenDone_}"													# what to do with the original files when done
	convertPrefs_a[2]="${movieTag_}"														# Finder tags for movie files
	convertPrefs_a[3]="${tvTag_}"															# Finder tags for TV show files
	convertPrefs_a[4]="${convertedTag_}"													# Finder tags for original files that have been transcoded
	convertPrefs_a[5]="${renameFile_}"														# whether or not to auto-rename files
	convertPrefs_a[6]="${movieFormat_}"														# movie rename format
	convertPrefs_a[7]="${tvShowFormat_}"													# TV show rename format
	convertPrefs_a[8]="${completedPath_}"													# where to put the transcoded files when complete
	convertPrefs_a[9]="${sshUser_}"															# get the ssh username
	convertPrefs_a[10]="${ingestPath_}"														# get the path to the ingest directory
	convertPrefs_a[11]="${extrasTag_}"														# Finder tags for Extra show files
	convertPrefs_a[12]="${outQuality_}"														# Output quality setting to use
	convertPrefs_a[13]="${logTag_}"															# Finder tags for log files
	convertPrefs_a[14]="${deleteAfterRemoteDelivery_}"										# delete original and transcoded files after remote delivery
	convertPrefs_a[15]="${addAllAudio_}"													# add all additional audio tracks
	convertPrefs_a[16]="${audioWidth_}"														# additional audio track widths
	
	for i in "${!convertPrefs_a[@]}"; do
																							# get the pref value
		if [[ "${i}" -eq 0 ]]; then
			returnPrefValues="${convertPrefs_a[${i}]}"
		else
			returnPrefValues="${returnPrefValues}:${convertPrefs_a[${i}]}"
		fi
	done
}

function ___main___ () {
	get_Prefs
	convert_Prefs2Str
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap "exit" INT																				# trap user cancelling
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors

define_Constants

___main___
																							# return the converted prefs string to AppleScript
echo "${returnPrefValues}"

exit 0