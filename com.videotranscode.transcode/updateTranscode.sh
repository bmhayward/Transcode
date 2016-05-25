#!/bin/sh

# PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH  #----- DO NOT INCLUDE PATH CHANGES, OTHERWISE gem update WILL NOT FUNCTION!!! -------

# set -xv; exec 1>>/tmp/updateTranscodeTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscode		
#	Copyright (c) 2016 Brent Hayward		
#
#
#	This script checks to see if Ruby Gems need to be udpated and logs the results to the system log
#	This script needs to be placed in Transcode_Update.app/Content/Resources
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.3, 05-23-2016"
	
	loggerTag="gem.update"
	
	readonly icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	
	# From brewAutoUpdate:
		# readonly libDir="${HOME}/Library"
		# readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
}

function __main__ () {
	define_Constants
	
	check4Updates
}

function check4Updates () {
	local gemVers=""
	local updateVT="false"
	local loopCounter=0
	local msgTxt="Transcode is ready to install "
	
	. "${sh_echoMsg}" "Checking for gem updates..." ""
	
	declare -a gemUpdates
	gemUpdates=( $(gem outdated) )
	
	if [ "${#gemUpdates[@]}" -gt "0" ]; then
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

				(( loopCounter++ ))
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
																			# open the Automator app to update the gems
				open "${appScriptsPath}/Transcode Updater.app"
			else
				. "${sh_echoMsg}" "User deferred update. Exiting..." ""
			fi
		else
			. "${sh_echoMsg}" "All gems are up-to-date. Exiting..." ""
			
		fi
	fi
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0