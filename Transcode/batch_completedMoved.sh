#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/batch_completedMovedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_completedMoved
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a wrapper to Don Melton's batch script which transcodes DVD and Blu-Ray content.
#	https://github.com/donmelton/video_transcoding
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.0, 02-16-2017"
	
	readonly LIBDIR="${HOME}/Library"
	
	readonly MOVEDWORKINGPLIST="com.videotranscode.completed.moved.working.plist"
	readonly MOVEDWORKINGPATH="${LIBDIR}/Preferences/${MOVEDWORKINGPLIST}"
	readonly INPROGRESSPLIST="com.videotranscode.completed.moved.inprogress.plist"
	readonly INPROGRESSPATH="${LIBDIR}/Preferences/${INPROGRESSPLIST}"
	readonly COMPLETEDWATCHPLIST="com.videotranscode.completed.watchfolder.plist"
}

function clean_Up () {
	if [[ -e "${MOVEDWORKINGPATH}" ]]; then
																							# remove the semaphore
		rm -f "${MOVEDWORKINGPATH}"
	fi
	
	if [[ -e "${INPROGRESSPATH}" ]]; then
																							# remove the semaphore
		rm -f "${INPROGRESSPATH}"
	fi
}

function __main__ () {
	local plistBuddy="/usr/libexec/PlistBuddy"
	local completedPath=""
	local plistFile=""
	local prefPath=""
	
	plistFile="${LIBDIR}/LaunchAgents/${COMPLETEDWATCHPLIST}"
																							# ----------- update com.videotranscode.completed.watchfolder.plist LaunchAgent -----------	
	if [[ -e "${plistFile}" ]]; then
																							# use the alias path to the Completed folder and prefs.plist
		prefPath="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
		completedPath=$(. "_aliasPath.sh" "${LIBDIR}/Application Support/Transcode/Completed alias")	
																							# update prefs.plist
		. "_writePrefs.sh" "${prefPath}" "CompletedDirectoryPath:${completedPath}"
		
		launchctl unload -w "${plistFile}" 2>&1
		${plistBuddy} -c 'Set :WatchPaths:0 "'"${completedPath}"'"' "${plistFile}"			# change the watch path in the LaunchAgent
		launchctl load -w "${plistFile}" 2>&1												# reload the LaunchAgent
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors

define_Constants
																							# set the semaphore
touch "${INPROGRESSPATH}"

__main__

exit 0