#!/bin/sh

# PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH #----- DO NOT INCLUDE PATH CHANGES, OTHERWISE gem update WILL NOT FUNCTION!!! -------

# set -xv; exec 1>>/tmp/updateTranscodeGemsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodeGems
#	Copyright (c) 2016 Brent Hayward		
#
#	
#	This script checks to see if Ruby Gems need to be udpated and logs the results to the system log
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.1, 05-01-2016"
	
	readonly scriptsDir="${HOME}/Library/Application Scripts"
	readonly libDir="${HOME}/Library"
	
	readonly icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"									# echo to the Terminal
	fi
    echo "${1}" 2>&1 | logger -t gem.update			# echo to syslog
}

function if_Error () {
	# ${1}: last line of error occurence
	# ${2}: error code of last command
	
	local lastLine="${1}"
	local lastErr="${2}"
																		# if lastErr > 0 then echo error msg and log
	if [[ ${lastErr} -eq 0 ]]; then
		echo_Msg "" ""
		echo_Msg "Something went awry :-(" ""
		echo_Msg "Script error encountered $(date) in ${scriptName}.sh: line ${lastLine}: exit status of last command: ${lastErr}" ""
		echo_Msg "Exiting..." ""
		
		exit 1
	fi
}

function updateGems () {
	local updateVT="false"
	
	echo_Msg "Checking for updates..." ""
	
	declare -a gemUpdates
	gemUpdates=( $(gem outdated) )

	if [ "${#gemUpdates[@]}" -gt "0" ]; then
		msgTxt="Transcode successfully updated"
																	# update the gems
		if [[ ${gemUpdates[*]} =~ video_transcoding ]]; then
			local updateVT="true"
																	# upgrade video_transcoding
			echo_Msg "Updating transcode-video..." ""
			sudo gem update video_transcoding 2>&1 | logger -t gem.video_transcoding.update
			gem cleanup video_transcoding 2>&1 | logger -t gem.video_transcoding.update
			
			msgTxt="${msgTxt} video_transcoding"
		fi

		if [[ ${gemUpdates[*]} =~ terminal-notifier ]]; then
																	# upgrade terminal-notifier
			echo_Msg "Updating terminal-notifier..." ""
			sudo gem update terminal-notifier 2>&1 | logger -t gem.terminal-notifier.update
			gem cleanup terminal-notifier 2>&1 | logger -t gem.terminal-notifier.update

			if [ "${updateVT}" = "false" ]; then
				msgTxt="${msgTxt} terminal-notifier"
			else
				msgTxt="${msgTxt} and terminal-notifier"
			fi
		fi
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
trap 'if_Error ${LINENO} $?' ERR																					# trap errors

__main__

exit 0