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
	local versStamp="Version 1.0.6, 06-25-2016"
	
	loggerTag="gem.update"
	
	readonly libDir="${HOME}/Library"
	
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	readonly icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	
	msgTxt="You're up-to-date!"
}

function updateGems () {
	local updateVT="false"
	
	. "${sh_echoMsg}" "Checking updates..." ""
	
	declare -a gemUpdates
	gemUpdates=( $(gem outdated) )

	if [ "${#gemUpdates[@]}" -gt "0" ]; then
		msgTxt="Transcode successfully updated"
																	# update the gems
		if [[ ${gemUpdates[*]} =~ video_transcoding ]]; then
			local updateVT="true"
																	# upgrade video_transcoding
			. "${sh_echoMsg}" "Updating video_transcoding gem..." ""
			sudo gem update video_transcoding 2>&1 | logger -t gem.video_transcoding.update
			gem cleanup video_transcoding 2>&1 | logger -t gem.video_transcoding.update
			
			msgTxt="${msgTxt} video_transcoding gem"
		fi

		if [[ ${gemUpdates[*]} =~ terminal-notifier ]]; then
																	# upgrade terminal-notifier
			. "${sh_echoMsg}" "Updating terminal-notifier gem..." ""
			sudo gem update terminal-notifier 2>&1 | logger -t gem.terminal-notifier.update
			gem cleanup terminal-notifier 2>&1 | logger -t gem.terminal-notifier.update

			if [ "${updateVT}" = "false" ]; then
				msgTxt="${msgTxt} terminal-notifier gem"
			else
				msgTxt="${msgTxt} and terminal-notifier gem"
			fi
		fi
	fi
}

function clean_Up () {
																	# remove the semaphore files
	rm -f "${libDir}/Preferences/com.videotranscode.gem.update.plist"
	rm -f "${libDir}/Preferences/com.videotranscode.gem.update.inprogress.plist"
}

function __main__ () {
	define_Constants
	
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
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates																									
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0