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
	local versStamp="Version 1.0.1, 05-01-2016"
	
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

function __main__ () {
	define_Constants
	
	check4Updates
}

function check4Updates () {
	local gemVers=""
	local updateVT="false"
	local loopCounter=0
	local msgTxt="Transcode is ready to install "
	
	echo_Msg "Checking for gem updates..." ""
	
	declare -a gemUpdates
	gemUpdates=( $(gem outdated) )
	
	if [ "${#gemUpdates[@]}" -gt "0" ]; then
																			# check which gems need to be updated
		if [[ ${gemUpdates[*]} =~ video_transcoding || ${gemUpdates[*]} =~ terminal-notifier ]]; then
			
			for i in "${gemUpdates[@]}"; do
			    if [[ "${i}" == *"video_transcoding"* ]]; then
					echo_Msg "Update available for video_transcoding" ""
				
					updateVT="true"
					gemVers="${gemUpdates[loopCounter+3]%)*}"
					msgTxt="${msgTxt} video_transcoding ${gemVers}"
			    fi

				if [[ "${i}" == *"terminal-notifier"* ]]; then
					echo_Msg "Update available for terminal-notifier" ""
					
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
				echo_Msg "User deferred update. Exiting..." ""
			fi
		else
			echo_Msg "All gems are up-to-date. Exiting..." ""
			
		fi
	fi
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																													# Execute
trap 'if_Error ${LINENO} $?' ERR																					# trap errors

__main__

exit 0