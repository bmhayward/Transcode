#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/watchFolder_rsyncTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_rsync
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
	local versStamp="Version 1.3.9, 03-22-2017"
	
	readonly WAITINGPLIST="com.videotranscode.rsync.batch.waiting.plist"
	readonly ONHOLDPLIST="com.videotranscode.rsync.batch.onhold.plist"
	readonly WORKINGPLIST="com.videotranscode.rsync.batch.working.plist"

	readonly LIBDIR="${HOME}/Library"
	readonly PREFDIR="${LIBDIR}/Preferences"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# returns CONVERTDIR and WORKDIR variables
	
	readonly ONHOLDPATH="${PREFDIR}/${ONHOLDPLIST}"	
	
	readonly BATCHCMD="${APPSCRIPTSPATH}/batch_rsync.sh"									# get the path to batch_rsync.sh
	
	readonly REMOTEDIR="/usr/local/Transcode/Remote"
}

function wait_4StableFolder () {
	local waitingPath="${PREFDIR}/${WAITINGPLIST}"
	
	touch "${waitingPath}"																	# create the waiting plist
	
	local prevSize=-1 																		# initialize variable
	local newSize=0													 						# Convert directory original size
	local tmpSize=${newSize}
	local upperLimit=3
	local sleepTime=30
	local diffTime=0
	local i=1
																							# check quickly to see if the directory has stabilized before moving to a longer wait period
	for ((i=1; i<=upperLimit; i++)); do
		sleep ${sleepTime}																	# wait for sizing information
		
		diffTime=$((sleepTime / upperLimit))
		sleepTime=$((sleepTime - diffTime))													# decrease the wait time
		
		if [[ ${i} -ne 1 ]]; then
			tmpSize=${newSize} 																# move to intermediate value
		fi
		
		newSize=$( du -s "${REMOTEDIR}" | awk '{print $1}' )								# get new file size
		prevSize=${tmpSize}
		
		if [[ ${i} -eq 1 && ${newSize} -eq 0 ]]; then
			sleep 7
			newSize=$( du -s "${REMOTEDIR}" | awk '{print $1}' )							# get new file size
		fi
																							# check to see if the directory stabilized or is empty
		shopt -s nullglob dotglob     														# include hidden files
		dirEmpty=("${REMOTEDIR}/"*)
		
		if [[ ${prevSize} -eq ${newSize} ]] || [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" == ".DS_Store" ]]; then
			prevSize=${newSize}																# need to set incase we got here because the directory was empty
			break
		fi
	done
																							# wait for the directory to be stable
	while [[ ${prevSize} != ${newSize} ]]; do 												# repeat until these values are the same
		sleep 60																			# check every 20 seconds after inital start

		tmpSize=${newSize} 																	# move to intermediate value
		newSize=$( du -s "${REMOTEDIR}" | awk '{print $1}' )								# get new file size
		prevSize=${tmpSize}
	done
	
	rm -f "${waitingPath}"																	# remove the waiting plist
}

function wait_4Working2Complete () {
	local workingPath="${PREFDIR}/${WORKINGPLIST}"
	
	touch "${ONHOLDPATH}"																	# create the on hold plist
	
	while [[ -e "${workingPath}" ]]; do 													# repeat until the on hold plist is deleted
		sleep 20 																			# check every 20 seconds
	done
}

function clean_Up () {
	shopt -s nullglob dotglob     															# include hidden files
	dirEmpty=("${REMOTEDIR}/"*)
																							# if the rsync directory is empty
	if [[ ${#dirEmpty[@]} -gt 0 ]]; then
		if [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" == ".DS_Store" ]]; then			# if the rsync directory has only 1 file and it is .DS_Store
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

if [[ -e "${PREFDIR}/${WAITINGPLIST}" ]] || [[ -e "${PREFDIR}/${ONHOLDPLIST}" ]]; then		# no need to hang around		
	echo "Nothing to see, here. Exiting..."
	exit 0
fi

if [[ -e "${PREFDIR}/${WORKINGPLIST}" ]]; then
	wait_4Working2Complete																	# wait for the current transcode process to complete
fi

if [[ -e "${ONHOLDPATH}" ]]; then															# need to remove the on hold plist
	rm -f "${ONHOLDPATH}"
fi

wait_4StableFolder																			# wait for all file additions to complete

shopt -s nullglob dotglob     																# include hidden files
dirEmpty=("${REMOTEDIR}/"*)
																							# if the Convert directory is not empty
if [[ ${#dirEmpty[@]} -eq 2 && ! " ${dirEmpty[@]##*/} " =~ " .~tmp~ " ]] || [[ ${#dirEmpty[@]} -gt 2 ]] ; then
																							# if the Remote directory has only 2 files and one is not .~tmp~. .DS_Store will always be there
	/bin/bash "${BATCHCMD}"																	# execute batch_rsync.sh to free watchFolder_rsync.sh to continue to watch
fi	

exit 0