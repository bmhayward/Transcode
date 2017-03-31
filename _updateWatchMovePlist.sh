#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_updateWatchMovePlistTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_updateWatchMovePlist		
#	Copyright (c) 2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	# ${1}: plist subkey name: transcode, ingest, completed, delete
	# ${2}: plist subkey value for PathState: e.g. /Users/hayward/Desktop/Transcode
	
	if [ $# -lt 2 ]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") LaunchAgent subkey name or subkey value not passed, exiting..."
	    exit 1
	fi
	
	readonly lDir="${HOME}/Library"
	readonly prfDir="${lDir}/Preferences"
	readonly plstBuddy="/usr/libexec/PlistBuddy"
	readonly plstName="com.videotranscode.watchfolders.moved"
	readonly plstFile="${lDir}/LaunchAgents/${plstName}.plist"
	readonly plistSubKeyName="${1}"
	readonly plistSubKeyValue="${2}"
	readonly transPrefPath="${workDir}/Prefs.plist"
}

function create_Plist () {
	local subKeyValue=""
	local watchScript=""
	
	watchScript="/usr/local/Transcode/watchFolder_watchFoldersMoved.sh"
																												# create the plist
	${plstBuddy} -c 'Add :Label string "'"${plstName}"'"' "${plstFile}"; cat "${plstFile}" > /dev/null 2>&1
	${plstBuddy} -c 'Add :ProgramArguments array' "${plstFile}"
	${plstBuddy} -c 'Add :ProgramArguments:0 string "'"${watchScript}"'"' "${plstFile}"
	${plstBuddy} -c 'Add :RunAtLoad bool true' "${plstFile}"

	declare -a keyName
	keyName[0]="transcode"
	keyName[1]="ingest"
	keyName[2]="completed"
																												# loop through the array getting values
	for i in "${keyName[@]}"; do		
		case "${i}" in
			transcode )
				if [[ "${plistSubKeyName}" == "transcode" ]] && [[ ! -z "${plistSubKeyValue}" ]]; then
																												# transcode, use the passed value
					subKeyValue="${plistSubKeyValue}"
				else
					subKeyValue="${workDir}"
				fi
			;;

			ingest )
				if [[ "${plistSubKeyName}" == "ingest" ]] && [[ ! -z "${plistSubKeyValue}" ]]; then
																												# ingest, use the passed value
					subKeyValue="${plistSubKeyValue}"
				else
					subKeyValue=$(. "_readPrefs.sh" "${transPrefPath}" "IngestDirectoryPath")
				fi
			;;

			completed )
				if [[ "${plistSubKeyName}" == "completed" ]] && [[ ! -z "${plistSubKeyValue}" ]]; then
					 																							# completed, use the passed value
					subKeyValue="${plistSubKeyValue}"
				else
					subKeyValue=$(. "_readPrefs.sh" "${transPrefPath}" "CompletedDirectoryPath")
				fi
			;;
		esac
																												# if not blank
			if [ ! -z "${subKeyValue}" ]; then
																												# add the subkey value to the plist
				${plstBuddy} -c 'Add :KeepAlive:PathState:"'"${subKeyValue}"'" bool true' "${plstFile}"
			fi
	done
	
	chmod 644 "${plstFile}"
																												# load the LaunchAgent	
	launchctl load "${plstFile}" 2>&1
}

function update_Plist () {
	local rsyncPlist=""
	local origSubKeyValue=""
																													# get the original subkey value
	case "${plistSubKeyName}" in
		transcode )
																													# read original path to Transcode from com.videotranscode.transcode.moved.working.plist
			origSubKeyValue=$(head -n 1 "${lDir}/Preferences/com.videotranscode.transcode.moved.working.plist")
			rsyncPlist="${lDir}/LaunchAgents/com.videotranscode.rsync.watchfolder.plist"
			
			if [ -e "${rsyncPlist}" ]; then
				launchctl unload "${rsyncPlist}" 2>&1																# unload the LaunchAgent	
				${plstBuddy} -c 'Set :WatchPaths:0 "'"${plistSubKeyValue}/Remote"'"' "${rsyncPlist}"				# change the rsync watch path in the LaunchAgent
				launchctl load "${rsyncPlist}" 2>&1																	# reload the LaunchAgent
			fi
		;;
		
		ingest | deleteIngest )
																													# read original path to Ingest from com.videotranscode.ingest.moved.working.plist
			origSubKeyValue=$(head -n 1 "${lDir}/Preferences/com.videotranscode.ingest.moved.working.plist")
		;;
		
		completed | deleteCompleted )
																													# read original path to Completed from com.videotranscode.completed.moved.working.plist
			origSubKeyValue=$(head -n 1 "${lDir}/Preferences/com.videotranscode.completed.moved.working.plist")
		;;
	esac
																													# unload the LaunchAgent
	launchctl unload "${plstFile}"	2>&1
	
	if [ ! -z "${origSubKeyValue}" ]; then
	 																												# delete a specific key
		${plstBuddy} -c 'Delete :KeepAlive:PathState:"'"${origSubKeyValue}"'"' "${plstFile}"
	fi
	
	if [ "${plistSubKeyName}" != *"delete"* ]; then
																													# set the subkey value
		${plstBuddy} -c 'Add :KeepAlive:PathState:"'"${plistSubKeyValue}"'" bool true' "${plstFile}"
	fi
																													# load the LaunchAgent
	launchctl load "${plstFile}" 2>&1
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.1.0, 01-23-2017

define_Constants "${@}"

if [ -e "${plstFile}" ]; then
	update_Plist
else
	create_Plist
fi