#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:${HOME}/Library/Scripts export PATH

# set -xv; exec 1>>/tmp/watchFolder_rsyncTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_rsync
#	Copyright (c) 2016 Brent Hayward
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
	local versStamp="Version 1.1.6, 05-19-2016"
	
	readonly waitingPlist="com.videotranscode.rsync.batch.waiting.plist"
	readonly onHoldPlist="com.videotranscode.rsync.batch.onhold.plist"
	readonly workingPlist="com.videotranscode.rsync.batch.working.plist"

	readonly libDir="${HOME}/Library"
	readonly prefDir="${libDir}/Preferences"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")								# get the path to the Transcode folder
	readonly convertDir="${workDir}/Remote"
	
	readonly onHoldPath="${prefDir}/${onHoldPlist}"	
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	
	readonly batchCMD="${appScriptsPath}/batch_rsync.sh"																# get the path to batch.command
}

function wait_4StableFolder () {
	local waitingPath="${prefDir}/${waitingPlist}"
	
	touch "${waitingPath}"																	# create the waiting plist
	
	local prevSize=-1 																		# initialize variable
	local newSize=0													 						# Convert directory original size
	local tmpSize=${newSize}
	local upperLimit=2
																							# check quickly to see if the directory has stabilized before moving to a longer wait period
	for ((i=1; i<=upperLimit; i++)); do
		sleep 5																			# wait for sizing information
		
		if [ ${i} -ne 1 ]; then
			tmpSize=${newSize} 																# move to intermediate value
		fi
		
		newSize=$( du -s "${convertDir}" | awk '{print $1}' )									# get new file size
		prevSize=${tmpSize}
																							# check to see if the directory stabilized or is empty
		shopt -s nullglob dotglob     														# include hidden files
		dirEmpty=("${convertDir}/"*)
		
		if [[ "${prevSize}" == "${newSize}" ]] || [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" = ".DS_Store" ]]; then
			prevSize=${newSize}																# need to set incase we got here because the directory was empty
			break
		fi
	done
																							# wait for the directory to be stable
	while [ ${prevSize} != ${newSize} ]; do 												# repeat until these values are the same
		sleep 20																			# check every 60 seconds after inital start

		tmpSize=${newSize} 																	# move to intermediate value
		newSize=$( du -s "${convertDir}" | awk '{print $1}' )									# get new file size
		prevSize=${tmpSize}
	done
	
	rm -f "${waitingPath}"																	# remove the waiting plist
}

function wait_4Working2Complete () {
	local workingPath="${prefDir}/${workingPlist}"
	
	touch "${onHoldPath}"																	# create the on hold plist
	
	while [ -e "${workingPath}" ]; do 														# repeat until the on hold plist is deleted
		sleep 20 																			# check every 20 seconds
	done	
}

function clean_Up () {
	shopt -s nullglob dotglob     																# include hidden files
	dirEmpty=("${convertDir}/"*)
																								# if the rsync directory is empty
	if [ ${#dirEmpty[@]} -gt 0 ]; then
		if [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" = ".DS_Store" ]]; then				# if the rsync directory has only 1 file and it is .DS_Store
																								# remove any left over semaphore files
			if [ -e "${prefDir}/com.videotranscode.rsync.batch.waiting.plist" ]; then
				rm -f "${prefDir}/com.videotranscode.rsync.batch.waiting.plist"
			fi

			if [ -e "${prefDir}/com.videotranscode.rsync.batch.onhold.plist" ]; then
				rm -f "${prefDir}/com.videotranscode.rsync.batch.onhold.plist"
			fi

			if [ -e "${prefDir}/com.videotranscode.rsync.batch.working.plist" ]; then
				rm -f "${prefDir}/com.videotranscode.rsync.batch.working.plist"
			fi
		fi
	fi
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																								# execute
trap clean_Up INT TERM EXIT																		# always run clean_Up regardless of how the script terminates

define_Constants

if [ -e "${prefDir}/${waitingPlist}" ] || [ -e "${prefDir}/${onHoldPlist}" ]; then				# no need to hang around		
	echo "Nothing to see, here. Exiting..."
	exit 0
fi

if [ -e "${prefDir}/${workingPlist}" ]; then
	wait_4Working2Complete																		# wait for the current transcode process to complete
fi

if [ -e "${onHoldPath}" ]; then																	# need to remove the on hold plist
	rm -f "${onHoldPath}"
fi

wait_4StableFolder																				# wait for all file additions to complete

shopt -s nullglob dotglob     																	# include hidden files
dirEmpty=("${convertDir}/"*)
																								# if the Convert directory is not empty
if [ ${#dirEmpty[@]} -gt 0 ]; then
	if [[ ${#dirEmpty[@]} -eq 1 && "${dirEmpty[0]##*/}" != ".DS_Store" ]] || [[ ${#dirEmpty[@]} -gt 1 ]]; then	# if the Convert directory has only 1 file and it is not .DS_Store
		. "${batchCMD}" || exit 1																# execute batch_rsync.sh
	fi
fi

exit 0