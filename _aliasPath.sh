#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_trimStringTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_aliasPath
#	Copyright (c) 2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function __alias__ () {
	# ${1}: path to the Finder alias

	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") path to the Finder alias not passed, exiting..."
	    exit 1
	fi
	    																					# Redirect stderr to dev null to suppress OSA environment errors
	exec 6>&2 																				# Link file descriptor 6 with stderr so we can restore stderr later
	exec 2>/dev/null 																		# stderr replaced by /dev/null

origPath=$(osascript << EOF
tell application "Finder"
set theItem to (POSIX file "$1") as alias
if the kind of theItem is "alias" then
get the posix path of ((original item of theItem) as text)
end if
end tell
EOF
)
	exec 2>&6 6>&-																			# Restore stderr and close file descriptor #6.

	echo "${origPath%/*}"																	# strip out trailing /	
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.3, 02-24-2017

__alias__ "${@}"