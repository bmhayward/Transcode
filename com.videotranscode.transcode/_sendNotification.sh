#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_sendNotificationTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_sendNotification		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function send_Notification () {
	# ${1}: title
	# ${2}: message
	# ${3}: subtitle
	# ${4}: sound
	
	local installedBrews=$(brew list)
	
	if [ -e "/usr/local/bin/terminal-notifier" ]; then
																																							# use terminal-notifier
		if [ $# -le 3 ]; then
			terminal-notifier -title "${1}" -message "${3}" -subtitle "${2}" -activate com.apple.Terminal													# no sound
		else
			terminal-notifier -title "${1}" -message "${3}" -subtitle "${2}" -activate com.apple.Terminal  -sound "${4}"									# sound
		fi
	else
																																							# use osacript
		if [ $# -le 3 ]; then
			osascript -e 'display notification "'"${3}"'" with title "'"${1}"'" subtitle "'"${2}"'"'														# no sound
		else
			osascript -e 'display notification "'"${3}"'" with title "'"${1}"'" subtitle "'"${2}"'" sound name "'"/System/Library/Sounds/${4}.aiff"'"'		# sound
		fi
		
	fi
}

function __main__ () {
	send_Notification "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.0, 04-02-2016

__main__ "${@}"