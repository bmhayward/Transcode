#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_sendNotificationTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_sendNotification		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __send_Notification__ () {
	# ${1}: title
	# ${2}: message
	# ${3}: subtitle
	# ${4}: sound
	
	local appIcon=""
	
	appIcon="${HOME}/Library/Application Support/Transcode/Transcode_custom.icns"
		
	if [[ -e "/usr/local/bin/terminal-notifier" ]]; then
																																							# use terminal-notifier
		if [[ $# -le 3 ]]; then
			terminal-notifier -title "${1}" -message "${3}" -subtitle "${2}" -activate com.apple.Terminal -contentImage "${appIcon}"						# no sound
		else
			terminal-notifier -title "${1}" -message "${3}" -subtitle "${2}" -activate com.apple.Terminal -sound "${4}"	-contentImage "${appIcon}"			# sound
		fi
	else
																																							# use osacript
		if [[ $# -le 3 ]]; then
			osascript -e 'display notification "'"${3}"'" with title "'"${1}"'" subtitle "'"${2}"'"'														# no sound
		else
			osascript -e 'display notification "'"${3}"'" with title "'"${1}"'" subtitle "'"${2}"'" sound name "'"/System/Library/Sounds/${4}.aiff"'"'		# sound
		fi
		
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.4, 03-31-2017

__send_Notification__ "${@}"