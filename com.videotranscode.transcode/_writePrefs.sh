#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_writePrefsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_writePrefs		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function write_Prefs () {
	# ${1}: path to the preferences file
	# ${2}: item(s) to be written to the preferences file. These are passed individually as [keyValue]:[prefValue] e.g. "OutputFileExt:m4v"
	
	local plistBuddy=""
	local plistFile=""
	local workDir=""
	local loopCounter=0
	local keyValue=""
	local prefValue=""
	local i=""
	local j=0
		
	plistBuddy="/usr/libexec/PlistBuddy"
	
	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") path to the preferences.plist not passed, exiting..."
	    exit 1
	fi
	
	declare -a passedArgs_a
	declare -a renameFormatPath_a
	
	renameFormatPath_a[0]="${LIBDIR}/Application Support/Transcode/Movie Format.txt"
	renameFormatPath_a[1]="${LIBDIR}/Application Support/Transcode/TV Format.txt"

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
		if [[ -e "${plistFile}" ]]; then
																							# remove the existing preference file
		   rm -f "${plistFile}"
		fi	
																							# get the current path to /Transcode
		workDir=$(. "/usr/local/Transcode/Library/_aliasPath.sh" "${HOME}/Library/Application Support/Transcode/Transcode alias")
																							# write out a new preference file
		declare -a defaultValue_a															# create the preference default key value array

		defaultValue_a[0]="m4v"																# get the transcode file extension
		defaultValue_a[1]="false"															# what to do with the original files when done
		defaultValue_a[2]="purple, Movie, VT"												# Finder tags for movie files
		defaultValue_a[3]="orange, TV Show, VT"												# Finder tags for TV show files
		defaultValue_a[4]="blue, Converted"													# Finder tags for original files that have been transcoded
		defaultValue_a[5]="true"															# whether or not to auto-rename files
		defaultValue_a[6]=""																# movie rename format
		defaultValue_a[7]='{n} - {'\''s'\''+s.pad(2)}e{e.pad(2)} - {t}'						# TV show rename format
		defaultValue_a[8]="${workDir}/Completed"											# where to output the transcoded files
		defaultValue_a[9]=""																# get the ssh username
		defaultValue_a[10]=""																# get the path to the rsync Remote directory
		defaultValue_a[11]="${workDir}/Convert"												# get the path to the ingest directory
		defaultValue_a[12]="yellow, Extra, VT"												# Finder tags for Extra show files
		defaultValue_a[13]="quick"															# Output quality setting to use											
		defaultValue_a[14]="Numbers.app"													# Log Analyzer helper app
		defaultValue_a[15]="log, VT"														# Finder tags for log files
		defaultValue_a[16]="false"															# transcoded files after remote delivery
		defaultValue_a[17]="false"															# show video preview if cropping is detected
		defaultValue_a[18]="false"															# add all additional audio tracks
		defaultValue_a[19]="stereo"															# additional audio track widths
		
		${plistBuddy} -c "Add :Label string com.videotranscode.prefs" "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		
		for i in "${prefKey_a[@]}"; do
				${plistBuddy} -c "Add :${i} string ${defaultValue_a[${loopCounter}]}" "${plistFile}"
			
			((++loopCounter))
		done
		
		j=6
		for i in "${renameFormatPath_a[@]}"; do
			if [[ -e "${i}" ]]; then
				rm -f "${i}"
			fi
																							# need to save the rename formats for movies and tv out to a separate text files
			printf "${defaultValue_a[${j}]}" >> "${i}"
			((++j))
		done
	else
																							# write out the passed preferences
		for i in "${passedArgs_a[@]}"; do
																							# the first value in the array passedArgs_a is the path to the preferences plist, so need to skip that one
			if [[ ${loopCounter} -gt 0 ]]; then
				keyValue="${i%%:*}"
				prefValue="${i##*:}"
																							# save to the plist
				${plistBuddy} -c "Set :${keyValue} ${prefValue}" "${plistFile}"
			fi

			((++loopCounter))
		done
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.3.7, 03-29-2017

write_Prefs "${@}"