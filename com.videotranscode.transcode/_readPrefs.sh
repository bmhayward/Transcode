#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_readPrefsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_readPrefs		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function read_Prefs () {
	# ${1}: path to the preferences file
	# ${2}: plist key(s) to read, can be a single key or multiple keys, optional
	# ${0}: returns individual plist value or multiple plist values if passed a key(s) to read
	
	local plistBuddy=""
	local plistFile=""
	local returnValue=""
	local keyValue=""
	local loopCounter=0
	local lineData=""
	local renameFormat=""
	local i=""
	local j=0
	
	plistBuddy="/usr/libexec/PlistBuddy"
	
	declare -a renameFormatPath_a	
	declare -a prefs_a
	declare -a passedArgs_a
	declare -a renameFormat_a
	
	renameFormatPath_a[0]="${LIBDIR}/Application Support/Transcode/Movie Format.txt"
	renameFormatPath_a[1]="${LIBDIR}/Application Support/Transcode/TV Format.txt"
																							# read in the rename movie and TV formats from the text files
	for i in "${renameFormatPath_a[@]}"; do
		while IFS='' read -r lineData || [[ -n "${lineData}" ]]; do
			renameFormat_a[${j}]="${lineData}"
		done < "${i}"
		((++j))
	done
		
	passedArgs_a=("${@}")
	
	plistFile="${passedArgs_a[0]}"
																							# create the preference key array			
	declare -a prefKey_a

	prefKey_a[0]="OutputFileExt"
	prefKey_a[1]="DeleteOriginal"
	prefKey_a[2]="MovieTags"
	prefKey_a[3]="TVTags"
	prefKey_a[4]="OriginalFileTags"
	prefKey_a[5]="AutoRename"
	prefKey_a[6]="MovieRenameFormat"
	prefKey_a[7]="TVRenameFormat"
	prefKey_a[8]="CompletedDirectoryPath"
	prefKey_a[9]="sshUser"
	prefKey_a[10]="RemoteDirectoryPath"
	prefKey_a[11]="IngestDirectoryPath"
	prefKey_a[12]="ExtrasTags"
	prefKey_a[13]="OutputQuality"
	prefKey_a[14]="TLAHelperApp"
	prefKey_a[15]="LogTags"
	prefKey_a[16]="DeleteAfterRemote"
	prefKey_a[17]="ShowCropPreview"
	prefKey_a[18]="AddAllAudio"
	prefKey_a[19]="AudioWidth"
	
	if [[ ${#passedArgs_a[@]} -eq 1 ]]; then
																							# read all the preferences
		for i in "${prefKey_a[@]}"; do
			prefs_a[${loopCounter}]=$(${plistBuddy} -c 'print :"'"${i}"'"' "${plistFile}")
	
			(( loopCounter++ ))
		done
																							# set the global preference variables
		outExt_="${prefs_a[0]}"																# get the output file extension

		if [[ "${outExt_}" == "mkv" ]]; then
			outExtOption_=""		
		else
			outExtOption_="--${outExt_}"
		fi

		deleteWhenDone_="${prefs_a[1]}"														# what to do with the original files when done
		movieTag_="${prefs_a[2]}"															# Finder tags for movie files
		tvTag_="${prefs_a[3]}"																# Finder tags for TV show files
		convertedTag_="${prefs_a[4]}"														# Finder tags for original files that have been transcoded
		renameFile_="${prefs_a[5]}"															# whether or not to auto-rename files
		movieFormat_="${renameFormat_a[0]}"													# movie rename format
		tvShowFormat_="${renameFormat_a[1]}"												# TV show rename format
		completedPath_="${prefs_a[8]}"														# where to put the transcoded files when complete
		sshUser_="${prefs_a[9]}"															# get the ssh username
		rsyncPath_="${prefs_a[10]}"															# get the path to the rsync Remote directory
		ingestPath_="${prefs_a[11]}"														# get the path to the ingest directory
		extrasTag_="${prefs_a[12]}"															# Finder tags for Extra show files
		outQuality_="${prefs_a[13]}"														# Output quality setting to use
		tlaApp_="${prefs_a[14]}"															# Log Analyzer helper app
		logTag_="${prefs_a[15]}"															# Finder tags for log files
		deleteAfterRemoteDelivery_="${prefs_a[16]}"											# delete original and transcoded files after remote delivery
		showCropPreview_="${prefs_a[17]}"													# show video preview if cropping is detected
		addAllAudio_="${prefs_a[18]}"														# add all additional audio tracks
		audioWidth_="${prefs_a[19]}"														# additional audio track widths

		if [[ "${tlaApp_##*.}" == "app" ]]; then
			tlaHelper="${tlaApp_}"
		else
			tlaHelper="${tlaApp_}.app"
		fi

		if [[ -z "${outQuality_}" ]]; then
			 outQualityOption_=""		
		else
			 outQualityOption_="${outQuality_}"
		fi
	else
		for i in "${passedArgs_a[@]}"; do
																							# the first value in the array passedArgs_a is the path to the preferences plist, so need to skip that one
			if [[ ${loopCounter} -eq 1 ]]; then
				case "${i}" in
					MovieRenameFormat )														# movie format
						returnValue="${renameFormat_a[0]}"
					;;
					
					TVRenameFormat )														# tv format
						returnValue="${renameFormat_a[1]}"
					;;
					
					* )																		# from plist
						returnValue=$(${plistBuddy} -c 'print :"'"${i}"'"' "${plistFile}")
					;;	
				esac
			elif [[ ${loopCounter} -gt 1 ]]; then
				case "${i}" in
					MovieRenameFormat )														# movie format
						returnValue="${returnValue}:${renameFormat_a[0]}"
					;;
					
					TVRenameFormat )														# tv format
						returnValue="${returnValue}:${renameFormat_a[1]}"
					;;
					
					* )																		# from plist
						returnValue="${returnValue}:"$(${plistBuddy} -c 'print :"'"${i}"'"' "${plistFile}")
					;;	
				esac
			fi

			(( loopCounter++ ))
		done
																							# return the preference value
		echo "${returnValue}"
	fi
}

function __get_Prefs__ () {
	local prefValue=""
	
	if [[ $# -lt 1 ]] || [[ ! -e "${1}" ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") path to the preferences.plist not passed or does not exist, exiting..."
	    exit 1
	fi
	
	if [[ $# -eq 1 ]]; then
																							# read all preferences
		read_Prefs "${@}"
	else
																							# read only the passed preference value
		prefValue=$(read_Prefs "${@}")
																							# return the preference value
		echo "${prefValue}"
	fi
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.2.5, 03-23-2017

__get_Prefs__ "${@}"