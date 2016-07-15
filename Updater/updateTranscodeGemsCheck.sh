#!/bin/sh

# PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH  #----- DO NOT INCLUDE PATH CHANGES, OTHERWISE WILL NOT FUNCTION!!! -------

# set -xv; exec 1>>/tmp/updateTranscodeGemsCheckTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodeGemsCheck
#	Copyright (c) 2016 Brent Hayward		
#
#	
#	This script is called by a launchAgent to see if Ruby Gems need to be udpated and logs the results to the system log
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.8, 07-14-2016"
	
	loggerTag="gem.update"
	
	readonly comLabel="com.videotranscode.transcode"
	
	readonly libDir="${HOME}/Library"
	readonly appScriptsPath="${libDir}/Application Scripts/${comLabel}"
	readonly prefDir="${libDir}/Preferences"

	readonly icnsPath="${appScriptsPath}/Transcode Updater.app/Contents/Resources/AutomatorApplet.icns"
	
	readonly plistBuddy="/usr/libexec/PlistBuddy"
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	disableLaunchAgent="false"
}

function check4Update_Gems () {
	local updateInProgressPlist="com.videotranscode.gem.update.inprogress.plist"
	local updateInProgessPath="${prefDir}/${updateInProgressPlist}"
	local gemVers=""
	local vtVers="0"
	local tnVers="0"
	local loopCounter=0
	local msgTxt="Transcode is ready to install"
	local plistDir="${libDir}/LaunchAgents"
	local plistName="com.videotranscode.gem.check"
	local plistFile="${plistDir}/${plistName}.plist"
																			# need to check for update?
	if [ ! -e "${updateInProgessPath}" ]; then
		. "${sh_echoMsg}" "Checking for gem updates..." ""
																			# get what needs to be updated
		declare -a gemUpdates
		gemUpdates=( $(gem outdated) )
																			# check which gems need to be updated
		if [[ ${gemUpdates[*]} =~ video_transcoding || ${gemUpdates[*]} =~ terminal-notifier ]]; then
			for i in "${gemUpdates[@]}"; do
			    if [[ "${i}" == *"video_transcoding"* ]]; then
					gemVers="${gemUpdates[loopCounter+3]%)*}"
					
					vtVers=$(/usr/local/bin/transcode-video --version)
					vtVers="${vtVers#* }"
					vtVers="${vtVers%%C*}"
																			# current version (vtVers) is not equal to the update available version (gemVers)
					if [ "${gemVers}" != "${vtVers}" ]; then
																			# write out the semphore file
						touch "${updateInProgessPath}"
						
						. "${sh_echoMsg}" "Update available for video_transcoding" ""

						vtVers="${gemVers}"
						msgTxt="${msgTxt} video_transcoding ${gemVers}"
					else
																			# nothing has changed, put back to default
						vtVers="0"
					fi
			    fi

				if [[ "${i}" == *"terminal-notifier"* ]]; then
																			# write out the semphore file
					touch "${updateInProgessPath}"
					
					. "${sh_echoMsg}" "Update available for terminal-notifier" ""

					gemVers="${gemUpdates[loopCounter+3]%)*}"
					tnVers="${gemVers}"
					
					if [ "${vtVers}" = "0" ]; then
						msgTxt="${msgTxt} terminal-notifier ${gemVers}"
					else
						msgTxt="${msgTxt} and terminal-notifier ${gemVers}"
					fi
				fi

				((loopCounter++))
			done
			
			if [ -e "${updateInProgessPath}" ]; then
																			# write out plist for use with updateTranscodeGems and Gem Updater.app
				plistName="com.videotranscode.gem.update"
				plistDir="/tmp"
				plistFile="${plistDir}/${plistName}.plist"
																			# delete the plist if it is hanging around
				if [ -e "${plistFile}" ]; then
					/bin/rm -f "${plistFile}"
				fi
																			# write out the plist to /tmp
				${plistBuddy} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
				${plistBuddy} -c 'Add :msgTxt string "'"${msgTxt}"'"' "${plistFile}"
				${plistBuddy} -c 'Add :video_transcoding string "'"${vtVers}"'"' "${plistFile}"
				${plistBuddy} -c 'Add :terminal-notifier string "'"${tnVers}"'"' "${plistFile}"

																			# open Transcode Updater Dialog.app
				open -a "${appScriptsPath}/Transcode Updater.app/Contents/Resources/Gem Updater.app"
			else
																			# no semaphore files available
				msgTxt=""
				disableLaunchAgent="true"
			fi
		else
			msgTxt="Already up-to-date."
			disableLaunchAgent="true"
																			# delete the sempahore file
			/bin/rm -f "${updateInProgessPath}"
		fi
	elif [ ! -e "${updateInProgessPath}" ]; then
																			# no semaphore files available
		msgTxt=""
		disableLaunchAgent="true"
	else
		msgTxt="Waiting for update approval, please click Install Update."
																			# bring the updater app to the front
		/usr/bin/open -a "${appScriptsPath}/Transcode Updater.app/Contents/Resources/Gem Updater.app"
	fi
	
	. "${sh_echoMsg}" "${msgTxt}" ""
	
	if [ "${disableLaunchAgent}" = "true" ]; then
		disable_launchAgent
	fi
}

function disable_launchAgent () {
	local plistDir="${libDir}/LaunchAgents"
	local plistName="com.videotranscode.gem.check"
	local plistFile="${plistDir}/${plistName}.plist"
																			# turn off launchAgent to run updateTranscodeGemsCheck.sh
	${plistBuddy} -c 'Set :Disabled true' "${plistFile}"
	/bin/launchctl unload "${plistFile}"
}

function __main__ () {
	define_Constants
	
	check4Update_Gems
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute																						
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0