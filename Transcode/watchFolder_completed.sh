#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/watchFolder_completedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_completed
#	Copyright (c) 2017 Brent Hayward
#
#	
#	This script watches a folder for files and executes once all file additions have completed
#
# 	create onHold plist in ~/Library/Preferences (in wait for working done function)
# 	wait for ${working} to be deleted (function)
# 	after working plist is deleted from ~/Library/Preferences
# 	wait for directory to be stable (function)
# 	delete onHold plist in ~/Library/Preferences
# otherwise
# 	create waiting plist in ~/Library/Preferences (in wait for directory stable function)
# 	wait for directory to be stable (function)
# 	after directory is stable (in wait for directory stable function)
# 	delete waiting plist in ~/Library/Preferences (in wait for directory stable function)
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.9, 02-16-2017"
	
	readonly LIBDIR="${HOME}/Library"
	readonly PREFDIR="${LIBDIR}/Preferences"
	
	readonly MOVEDWORKINGPLIST="com.videotranscode.completed.moved.working.plist"
	readonly WATCHMOVEDPLIST="com.videotranscode.watchfolders.moved.plist"
	
	readonly MOVEDWORKINGPATH="${LIBDIR}/Preferences/${MOVEDWORKINGPLIST}"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# returns CONVERTDIR and WORKDIR variables
	
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
	
	completedPath_=$(. "_readPrefs.sh" "${PREFPATH}" "CompletedDirectoryPath")				# read in the preferences from Prefs.txt
}

function moved_Check () {
	local plistFile=""
	
	if [[ ! -e "${completedPath_}" ]] && [[ ! -e "${PREFDIR}/${MOVEDWORKINGPLIST}" ]]; then
		plistFile="${LIBDIR}/LaunchAgents/${WATCHMOVEDPLIST}"
																							# set the semaphore
		touch "${MOVEDWORKINGPATH}"
		printf '%s\n' "${completedPath_}" >> "${MOVEDWORKINGPATH}"

		launchctl unload -w "${plistFile}" 2>&1												# unload the LaunchAgent
		sleep .1
		launchctl load -w "${plistFile}" 2>&1												# load the LaunchAgent
		
		echo "Completed moved, updating location"
		exit 0		
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
define_Constants

moved_Check

if [[ -e "${PREFDIR}/${WATCHMOVEDPLIST}" ]]; then
																							# no need to hang around		
	echo "Nothing to see, here. Exiting..."
	exit 0
fi

exit 0