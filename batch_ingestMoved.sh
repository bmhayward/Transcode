#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/batch_ingestMovedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_ingestMoved
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a wrapper to Don Melton's batch script which transcodes DVD and Blu-Ray content.
#	https://github.com/donmelton/video_transcoding
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.2.6, 02-16-2017"
	
	readonly LIBDIR="${HOME}/Library"
	
	readonly MOVEDWORKINGPLIST="com.videotranscode.ingest.moved.working.plist"
	readonly MOVEDWORKINGPATH="${LIBDIR}/Preferences/${MOVEDWORKINGPLIST}"
	readonly INPROGRESSPLIST="com.videotranscode.ingest.moved.inprogress.plist"
	readonly INPROGRESSPATH="${LIBDIR}/Preferences/${INPROGRESSPLIST}"
	readonly INGESTWATCHPLIST="com.videotranscode.ingest.watchfolder.plist"
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
	local ingestPath=""
	local plistFile=""
	local prefPath=""
	
	plistFile="${LIBDIR}/LaunchAgents/${INGESTWATCHPLIST}"
																							# ----------- update com.videotranscode.ingest.watchfolder.plist LaunchAgent -----------
	if [[ -e "${plistFile}" ]]; then
																							# get the alias path to the Ingest folder and prefs.plist
		prefPath="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
		ingestPath=$(. "_aliasPath.sh" "${LIBDIR}/Application Support/Transcode/Ingest alias")
																							# update prefs.plist
		. "_writePrefs.sh" "${prefPath}" "IngestDirectoryPath:${ingestPath}"
					
		launchctl unload -w "${plistFile}" 2>&1												# unload the LaunchAgent	
		${plistBuddy} -c 'Set :WatchPaths:0 "'"${ingestPath}"'"' "${plistFile}"				# change the watch path in the LaunchAgent
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