#!/bin/sh

# PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH  #----- DO NOT INCLUDE PATH CHANGES, OTHERWISE WILL NOT FUNCTION!!! -------

# set -xv; exec 1>>/tmp/updateTranscodeGemsCheckTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodeGemsCheck
#	Copyright (c) 2016-2017 Brent Hayward		
#
#	
#	This script is called by a LaunchAgent to see if Ruby Gems need to be udpated and logs the results to the system log
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.4, 02-04-2017"
	
	loggerTag="gem.update"
	
	readonly LIBDIR="${HOME}/Library"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	readonly LIBSCRIPTSPATH="${APPSCRIPTSPATH}/Library"
	
	readonly PREFDIR="${LIBDIR}/Preferences"
	
	readonly PLISTBUDDY="/usr/libexec/PlistBuddy"
	readonly SH_ECHOMSG="${LIBSCRIPTSPATH}/_echoMsg.sh"
	readonly SH_IFERROR="${LIBSCRIPTSPATH}/_ifError.sh"
}

function wait4Idle () {
	# returns: flag true=0 or false=1
	
	local idleTime=0
	local dwellTime=0
	local waitDuration=0
	local duration=0
	local returnValue=1
	
	dwellTime=120																			# two minutes
	waitDuration=28800																		# 8 hours
	
	SECONDS=0
																							# wait for two minutes of idle time, but wait no more than the dwell time in total
	while [[ "${idleTime}" -lt "${dwellTime}" && "${duration}" -lt "${waitDuration}" ]]; do
		sleep 5

		idleTime=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
		
		duration=${SECONDS}
	done
																							# if waited less than 8 hours, OK to proceed
	if [[ "${duration}" -lt "${waitDuration}" ]]; then
		returnValue=0
	fi
	
	return ${returnValue}
}

function check4Update_Gems () {
	local updateInProgressPlist=""
	local updateInProgessPath=""
	local gemVers=""
	local vtVers=""
	local tnVers=""
	local loopCounter=0
	local msgTxt=""
	local plistDir=""
	local plistName=""
	local plistFile=""
	
	updateInProgressPlist="com.videotranscode.gem.update.inprogress.plist"
	updateInProgessPath="${PREFDIR}/${updateInProgressPlist}"
	vtVers="0"
	tnVers="0"
	msgTxt="Transcode is ready to install"
	plistDir="${LIBDIR}/LaunchAgents"
	plistName="com.videotranscode.gem.check"
	plistFile="${plistDir}/${plistName}.plist"
																							# need to check for update?
	if [[ ! -e "${updateInProgessPath}" ]]; then
		. "${SH_ECHOMSG}" "Checking for gem updates..." ""
																							# get what needs to be updated
		declare -a gemUpdates_a
		
		gemUpdates_a=( $(gem outdated) )
																							# check which gems need to be updated
		if [[ ${gemUpdates_a[*]} =~ video_transcoding ]]; then
			for i in "${gemUpdates_a[@]}"; do
			    if [[ "${i}" == *"video_transcoding"* ]]; then
					gemVers="${gemUpdates_a[loopCounter+3]%)*}"
					
					vtVers=$(/usr/local/bin/transcode-video --version)
					vtVers="${vtVers#* }"
					vtVers="${vtVers%%C*}"
																							# current version (vtVers) is not equal to the update available version (gemVers)
					if [[ "${gemVers}" != "${vtVers}" ]]; then
																							# write out the semphore file
						touch "${updateInProgessPath}"
						
						. "${SH_ECHOMSG}" "Update available for video_transcoding" ""

						vtVers="${gemVers}"
						msgTxt="${msgTxt} video_transcoding ${gemVers}"
					else
																							# nothing has changed, put back to default
						vtVers="0"
					fi
			    fi

				((loopCounter++))
			done
			
			if [[ -e "${updateInProgessPath}" ]]; then
																							# write out plist for use with updateTranscodeGems and Gem Updater.app
				plistName="com.videotranscode.gem.update"
				plistDir="/tmp"
				plistFile="${plistDir}/${plistName}.plist"
																							# delete the plist if it is hanging around
				if [[ -e "${plistFile}" ]]; then
					/bin/rm -f "${plistFile}"
				fi
																							# write out the plist to /tmp
				${PLISTBUDDY} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
				${PLISTBUDDY} -c 'Add :msgTxt string "'"${msgTxt}"'"' "${plistFile}"
				${PLISTBUDDY} -c 'Add :video_transcoding string "'"${vtVers}"'"' "${plistFile}"
				${PLISTBUDDY} -c 'Add :terminal-notifier string "'"${tnVers}"'"' "${plistFile}"
																							# wait for two minutes of idle time before continuing
				# if wait4Idle ; then
																							# open Transcode Updater Dialog.app
					/usr/bin/open -a "${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/Gem Updater.app"
				# fi
			else
																							# no semaphore files available
				msgTxt=""
			fi
		else
			msgTxt="Already up-to-date."
																							# delete the sempahore file
			/bin/rm -f "${updateInProgessPath}"
		fi
	elif [[ ! -e "${updateInProgessPath}" ]]; then
																							# no semaphore files available
		msgTxt=""
	else
		msgTxt="Waiting for update approval, please click Install Update."
		
		if wait4Idle ; then
																							# bring the updater app to the front
			/usr/bin/open -a "${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/Gem Updater.app"
		fi
	fi
	
	. "${SH_ECHOMSG}" "${msgTxt}" ""
}

function __main__ () {
	define_Constants
	
	check4Update_Gems
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute																						
trap '. "${SH_IFERROR}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0