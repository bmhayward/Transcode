#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/tmp/_mkFinderAliasTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_mkFinderAlias
#	Copyright (c) 2016-2017 Brent Hayward
#		
#	
#	This script creates a Finder alias
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function mk_Alias () {
	# ${1}: The name (relative or full path) of a source file or folder (directory)
	# ${2}: The name (relative or full path) of a destination folder (directory)
	# ${3}: Name of the alias
	
	if [[ $# -lt 3 ]]; then
		. "_echoMsg.sh" "Usage: ${scriptName} srcPath destPath, alias name exiting..."
	    exit 1
	fi
	
	local srcType=""
	local scriptName=""
	local srcPath=""																		# remove possible trailing slash from ${1}
	local destPath=""
	
	scriptName=$(basename "${0}")
	srcPath="${1%/}"																		# remove possible trailing slash from ${1}
	destPath="${2}"
																							# check if the ${scrPath} directory exists
	if [[ ! -e "${srcPath}" ]]; then
		. "_echoMsg.sh" "{scriptName}: ${srcPath}: No such file or directory, exiting..."
		exit 1
	fi
																							# check if the ${destPath} directory exists
	if [[ ! -d "${destPath}" ]]; then
		. "_echoMsg.sh" "${scriptName}: ${destPath}: No such directory, exiting..."
		exit 1
	fi
																							# check if we have permission to create a new file in the ${destPath} directory
	if [[ ! -w "${destPath}" ]]; then
		. "_echoMsg.sh" "${scriptName}: No write permission in the directory ${destPath}, exiting..."
		exit 1
	fi
																							# set ${srcType} to "file" or "folder" as appropriate
	if [[ -d "${srcPath}" ]]; then
	    if [[ "${srcPath##*.}" == "app" ]]; then
	        srcType="file"
	    else
	        srcType="folder"
	    fi
	else
	    srcType="file"
	fi

	case ${srcPath} in
		/* )
			fullSrcPath=${srcPath}
		;;
		
		~* )
			fullSrcPath=${srcPath}
		;;
		
		* )
			fullSrcPath=$(pwd)/${srcPath}
		;;
	esac

	case ${destPath} in
		/* )
			fullDestPath=${destPath}
		;;
		
		~* )
			fullDestPath=${destPath}
		;;
		
		* )
			fullDestPath=$(pwd)/${destPath}
		;;
	esac

cat << EOF | osascript -l AppleScript > /dev/null
tell application "Finder"
	set source_file to (POSIX file "$fullSrcPath") as text
	set alias_dir to (POSIX file "$fullDestPath") as text
	make new alias at alias_dir to source_file
	set name of result to "$3"
end tell
EOF

}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.8, 02-04-2017"

mk_Alias "${@}"