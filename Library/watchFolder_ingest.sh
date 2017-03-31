#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/watchFolder_ingestTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_ingest
#	Copyright (c) 2016-2017 Brent Hayward
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
	local versStamp="Version 1.4.6, 03-24-2017"
	
	readonly LIBDIR="${HOME}/Library"
	readonly PREFDIR="${LIBDIR}/Preferences"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	
	readonly WAITINGPLIST="com.videotranscode.ingest.batch.waiting.plist"
	readonly ONHOLDPLIST="com.videotranscode.ingest.batch.onhold.plist"
	readonly WORKINGPLIST="com.videotranscode.ingest.batch.working.plist"
	readonly MOVEDWORKINGPLIST="com.videotranscode.ingest.moved.working.plist"
	readonly WATCHMOVEDPLIST="com.videotranscode.watchfolders.moved.plist"
	
	readonly MOVEDWORKINGPATH="${LIBDIR}/Preferences/${MOVEDWORKINGPLIST}"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# returns CONVERTDIR and WORKDIR variables
	
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
	readonly ONHOLDPATH="${PREFDIR}/${ONHOLDPLIST}"
	
	readonly BATCHCMD="${APPSCRIPTSPATH}/batch_ingest.sh"									# get the path to batch_ingest.command
	
	ingestPath_=$(. "_readPrefs.sh" "${PREFPATH}" "IngestDirectoryPath")					# read in the preferences from Prefs.txt
}

function moved_Check () {
	local plistFile=""
	
	if [[ ! -e "${ingestPath_}" ]] && [[ ! -e "${PREFDIR}/${MOVEDWORKINGPLIST}" ]]; then
		plistFile="${LIBDIR}/LaunchAgents/${WATCHMOVEDPLIST}"
																							# set the semaphore
		touch "${MOVEDWORKINGPATH}"
		printf '%s\n' "${ingestPath_}" >> "${MOVEDWORKINGPATH}"

		launchctl unload -w "${plistFile}" 2>&1												# unload the LaunchAgent
		sleep .1
		launchctl load -w "${plistFile}" 2>&1												# load the LaunchAgent to force the reload of the LaunchAgent
		
		echo "Ingest moved, updating location"
		exit 0		
	fi
}

function wait_4StableFolder () {
	local waitingPath="${PREFDIR}/${WAITINGPLIST}"
	
	touch "${waitingPath}"																	# create the waiting plist
	
	local prevSize=-1 																		# initialize variable
	local newSize=0													 						# Convert directory original size
	local tmpSize=${newSize}
	local upperLimit=2
	local sleepTime=20
	local diffTime=0
																							# if trancoding is active allow for more time for ingest
	if [[ -e "${PREFDIR}/${WORKINGPLIST}" ]]; then
		upperLimit=3
		sleepTime=30
	else
		. "_sendNotification.sh" "Transcode" "Scanning Ingest folder…"
	fi
																							# check quickly to see if the directory has stabilized before moving to a longer wait period
	for ((i=1; i<=upperLimit; i++)); do
		sleep ${sleepTime}																	# wait for sizing information
		
		diffTime=$((sleepTime / upperLimit))
		sleepTime=$((sleepTime - diffTime))													# decrease the wait time
		
		if [[ ${i} -ne 1 ]]; then
			tmpSize=${newSize} 																# move to intermediate value
		fi
		
		newSize=$( du -s "${ingestPath_}" | awk '{print $1}' )								# get new file size
		prevSize=${tmpSize}
																							# sleep a little longer if first loop through and file size is 0, just to make sure we are not waiting on the DVD reader
		if [[ ${i} -eq 1 && ${newSize} -eq 0 ]]; then
			sleep 10
			newSize=$( du -s "${ingestPath_}" | awk '{print $1}' )							# get new file size
		fi
																							# check to see if the directory stabilized or is empty
		shopt -s nullglob dotglob															# include hidden files												
		dirEmpty=("${ingestPath_}/"*)
				
		if [[ ${prevSize} -eq ${newSize} ]] || [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" == ".DS_Store" ]]; then
			prevSize=${newSize}																# need to set incase we got here because the directory was empty
			break
		fi
	done
																							# wait for the directory to be stable
	while [[ ${prevSize} != ${newSize} ]]; do 												# repeat until these values are the same
		sleepTime=60
																							# if trancoding is active allow for more time for ingest
		if [[ -e "${PREFDIR}/com.videotranscode.batch.working.plist" ]]; then
			sleepTime=90
		fi
		
		sleep ${sleepTime}																	# check every ${sleepTime} seconds after inital start

		tmpSize=${newSize} 																	# move to intermediate value
		newSize=$( du -s "${ingestPath_}" | awk '{print $1}' )								# get new file size
		prevSize=${tmpSize}
	done	
	
	rm -f "${waitingPath}"																	# remove the waiting plist
}

function wait_4Working2Complete () {
	local workingPath="${PREFDIR}/${WORKINGPLIST}"
	
	touch "${ONHOLDPATH}"																	# create the on hold plist
	
	while [[ -e "${workingPath}" ]]; do 														# repeat until the on hold plist is deleted
		sleep 20 																			# check every 20 seconds
	done	
}

function clean_Up () {
	shopt -s nullglob dotglob     															# include hidden files
	dirEmpty=("${ingestPath_}/"*)
																							# if the Ingest directory is empty
	if [[ ${#dirEmpty[@]} -gt 0 ]]; then
		if [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" == ".DS_Store" ]]; then			# if the Ingest directory has only 1 file and it is .DS_Store
																							# remove any left over semaphore files
			if [[ -e "${PREFDIR}/${WAITINGPLIST}" ]]; then
				rm -f "${PREFDIR}/${WAITINGPLIST}"
			fi

			if [[ -e "${PREFDIR}/${ONHOLDPLIST}" ]]; then
				rm -f "${PREFDIR}/${ONHOLDPLIST}"
			fi

			if [[ -e "${PREFDIR}/${WORKINGPLIST}" ]]; then
				rm -f "${PREFDIR}/${WORKINGPLIST}"
			fi
		fi
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates

define_Constants

moved_Check

if [[ -e "${PREFDIR}/${WAITINGPLIST}" ]] || [[ -e "${PREFDIR}/${ONHOLDPLIST}" ]] || [[ -e "${PREFDIR}/${WATCHMOVEDPLIST}" ]]; then
																							# no need to hang around		
	echo "Nothing to see, here. Exiting..."
	exit 0
fi

if [[ -e "${PREFDIR}/${WORKINGPLIST}" ]]; then
	wait_4Working2Complete																	# wait for the current transcode process to complete
fi

if [[ -e "${ONHOLDPATH}" ]]; then																# need to remove the on hold plist
	rm -f "${ONHOLDPATH}"
fi

wait_4StableFolder																			# wait for all file additions to complete

shopt -s nullglob dotglob     																# include hidden files
dirEmpty=("${ingestPath_}/"*)
																							# if the Convert directory is not empty
if [[ ${#dirEmpty[@]} -gt 1 ]]; then											
	/bin/bash "${BATCHCMD}"																	# execute batch_ingest.sh
fi

exit 0