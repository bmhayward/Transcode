#!/bin/sh

# PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH #----- DO NOT INCLUDE PATH CHANGES, OTHERWISE gem update WILL NOT FUNCTION!!! -------

# set -xv; exec 1>>/tmp/updateTranscodeGemsCheckTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodeGemsCheck
#	Copyright (c) 2016 Brent Hayward		
#
#	
#	This script is called by updateTranscode.sh and checks to see if Ruby Gems need to be udpated and logs the results to the system log
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.3, 06-28-2016"
	
	loggerTag="gem.update"
	
	readonly comLabel="com.videotranscode.transcode"
	
	readonly libDir="${HOME}/Library"
	readonly appScriptsPath="${libDir}/Application Scripts/${comLabel}"
	readonly prefDir="${libDir}/Preferences"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")

	readonly icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
}

function __main__ () {
	define_Constants
	
	declare -a gemUpdates

	update_Gems
}

function clean_Up () {
																			# remove update script
	rm -f "/tmp/updateTranscode.sh"
}

function update_Gems () {
	local needsUpdatePlist="com.videotranscode.gem.update.plist"
	local needsUpdatePath="${prefDir}/${needsUpdatePlist}"
	local updateInProgressPlist="com.videotranscode.gem.update.inprogress.plist"
	local updateInProgessPath="${prefDir}/${updateInProgressPlist}"
	local updateVT="false"
	local gemVers=""
	local loopCounter=0
	local msgTxt="Transcode is ready to install"
																			# need to update?
	if [[ -e "${needsUpdatePath}" && ! -e "${updateInProgessPath}" ]]; then
		. "${sh_echoMsg}" "Checking for gem updates..." ""
																			# write out the semphore file
		touch "${updateInProgessPath}"
																			# get what needs to be updated
		gemUpdates=( $(gem outdated) )
																			# check which gems need to be updated
		if [[ ${gemUpdates[*]} =~ video_transcoding || ${gemUpdates[*]} =~ terminal-notifier ]]; then
			for i in "${gemUpdates[@]}"; do
			    if [[ "${i}" == *"video_transcoding"* ]]; then
					. "${sh_echoMsg}" "Update available for video_transcoding" ""
		
					updateVT="true"
					gemVers="${gemUpdates[loopCounter+3]%)*}"
					msgTxt="${msgTxt} video_transcoding ${gemVers}"
			    fi

				if [[ "${i}" == *"terminal-notifier"* ]]; then
					. "${sh_echoMsg}" "Update available for terminal-notifier" ""
			
					gemVers="${gemUpdates[loopCounter+3]%)*}"
					if [ "${updateVT}" = "false" ]; then
						msgTxt="${msgTxt} terminal-notifier ${gemVers}"
					else
						msgTxt="${msgTxt} and terminal-notifier ${gemVers}"
					fi
				fi

				((loopCounter++))
			done
																			# display update notification dialog
			local btnPressed=$(/usr/bin/osascript << EOT
			set iconPath to "$icnsPath" as string
			set posixPath to POSIX path of iconPath
			set hfsPath to POSIX file posixPath

			set btnPressed to display dialog "$msgTxt" buttons {"Install Later", "Install Update"} default button "Install Update" with title "Transcode" with icon file hfsPath

			if button returned of the result is "Install Later" then
				return 1
			else
				return 0
			end if
			EOT)

			if [ "${btnPressed}" = "0" ] ; then
				msgTxt="Requesting update."
																			# open the Automator app to update the gems
				open "${appScriptsPath}/Transcode Updater.app"
			else
				msgTxt="User deferred update."
																			# delete the sempahore file
				rm -f "${needsUpdatePath}"
				rm -f "${updateInProgessPath}"
			fi
		else
			msgTxt="Already up-to-date."
																			# delete the sempahore file
			rm -f "${needsUpdatePath}"
			rm -f "${updateInProgessPath}"
		fi
	elif [[ ! -e "${needsUpdatePath}" && ! -e "${updateInProgessPath}" ]]; then
																			# no semaphore files available
		msgTxt=""
	else
		msgTxt="Waiting for update approval, please click Install Update." ""
																			# bring Transcode Updater.app to the front
		open "${appScriptsPath}/Transcode Updater.app"
	fi
	
	. "${sh_echoMsg}" "${msgTxt}" ""	
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0