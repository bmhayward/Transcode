#!/bin/sh

# PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH #----- DO NOT INCLUDE PATH CHANGES, OTHERWISE gem update WILL NOT FUNCTION!!! -------

# set -xv; exec 1>>/tmp/updateTranscodeGemsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodeGems
#	Copyright (c) 2016 Brent Hayward		
#
#	
#	This script is called from Transcode Updater.app to see if Ruby Gems need to be udpated and logs the results to the system log
#	This script needs to be placed in Transcode_Update.app/Content/Resources
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.4, 05-24-2016"
	
	loggerTag="gem.update"
	
	readonly libDir="${HOME}/Library"
	
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	readonly icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
}

function updateGems () {
	local updateVT="false"
	
	. "${sh_echoMsg}" "Checking for updates..." ""
	
	declare -a gemUpdates
	gemUpdates=( $(gem outdated) )

	if [ "${#gemUpdates[@]}" -gt "0" ]; then
		msgTxt="Transcode successfully updated"
																	# update the gems
		if [[ ${gemUpdates[*]} =~ video_transcoding ]]; then
			local updateVT="true"
																	# upgrade video_transcoding
			. "${sh_echoMsg}" "Updating transcode-video..." ""
			sudo gem update video_transcoding 2>&1 | logger -t gem.video_transcoding.update
			gem cleanup video_transcoding 2>&1 | logger -t gem.video_transcoding.update
			
			msgTxt="${msgTxt} video_transcoding"
		fi

		if [[ ${gemUpdates[*]} =~ terminal-notifier ]]; then
																	# upgrade terminal-notifier
			. "${sh_echoMsg}" "Updating terminal-notifier..." ""
			sudo gem update terminal-notifier 2>&1 | logger -t gem.terminal-notifier.update
			gem cleanup terminal-notifier 2>&1 | logger -t gem.terminal-notifier.update

			if [ "${updateVT}" = "false" ]; then
				msgTxt="${msgTxt} terminal-notifier"
			else
				msgTxt="${msgTxt} and terminal-notifier"
			fi
		fi
																	# remove the semaphore file
		rm -f "${libDir}/Preferences/com.videotranscode.transcode.gem.update.plist"
	fi
}

function __main__ () {
	define_Constants
	
	msgTxt="You're up-to-date!"
	
	updateGems
	
cat << EOF | osascript -l AppleScript > /dev/null
set iconPath to "$icnsPath" as string
set posixPath to POSIX path of iconPath
set hfsPath to POSIX file posixPath

display dialog "$msgTxt" buttons {"OK"} default button "OK" with title "Transcode" with icon file hfsPath
EOF
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0