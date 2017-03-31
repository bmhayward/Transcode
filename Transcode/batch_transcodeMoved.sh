#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/batch_transcodeMovedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_transcodeMoved
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite.
#	It is called by watchFolder_transcodeMoved.sh.
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.4.0, 02-16-2017"
	
	readonly LIBDIR="${HOME}/Library"
	
	readonly MOVEDWORKINGPLIST="com.videotranscode.transcode.moved.working.plist"
	readonly MOVEDWORKINGPATH="${LIBDIR}/Preferences/${MOVEDWORKINGPLIST}"
	readonly INPROGRESSPLIST="com.videotranscode.transcode.moved.inprogress.plist"
	readonly INPROGRESSPATH="${LIBDIR}/Preferences/${INPROGRESSPLIST}"
	readonly TRANSCODEWATCHPLIST="com.videotranscode.watchfolder.plist"
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
	local transPath=""
	local plistFile=""

	plistFile="${LIBDIR}/LaunchAgents/${TRANSCODEWATCHPLIST}"
																							# ----------- update com.videotranscode.watchfolder.plist LaunchAgent -----------
	if [[ -e "${plistFile}" ]]; then
																							# get the alias path to the Transcode folder
		transPath=$(. "_aliasPath.sh" "${LIBDIR}/Application Support/Transcode/Transcode alias")
					
		launchctl unload -w "${plistFile}" 2>&1												# unload the LaunchAgent	
		${plistBuddy} -c 'Set :WatchPaths:0 "'"${transPath}/Convert"'"' "${plistFile}"		# change the watch path in the LaunchAgent
		launchctl load -w "${plistFile}" 2>&1												# reload the LaunchAgent
		
		# need to reset the rsync watchFolder if it exists
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