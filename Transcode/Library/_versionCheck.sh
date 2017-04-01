#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_versionCheckTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_versionCheck 			
#	Copyright (c) 2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
# 


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function version_Check () {
	# ${1}: minOS
	
	if [[ $# -lt 1 ]]; then
		. "_echoMsg.sh" "Usage: $(basename "${0}") minimum macOS version not passed, exiting..."
	    exit 1
	fi
	
	local ver1Front=""
	local ver1Back=""
	local ver2Front=""
	local ver2Back=""
																							# this function returns 10 if $1=$2, 11 if $1>$2, or 9 otherwise	
	[[ "${1}" == "${2}" ]] && return 10

	ver1Front=$(echo "${1}" | cut -d "." -f -1)
	ver1Back=$(echo "${1}" | cut -d "." -f 2-)

	ver2Front=$(echo "${2}" | cut -d "." -f -1)
	ver2Back=$(echo "${2}" | cut -d "." -f 2-)

	if [[ "${ver1Front}" != "${1}" ]] || [[ "${ver2Front}" != "${2}" ]]; then
		[[ "${ver1Front}" -gt "${ver2Front}" ]] && return 11
		[[ "${ver1Front}" -lt "${ver2Front}" ]] && return 9

		[[ "${ver1Front}" == "${1}" ]] || [[ -z "${ver1Back}" ]] && ver1Back=0
		[[ "${ver2Front}" == "${2}" ]] || [[ -z "${ver2Back}" ]] && ver2Back=0
		
		version_Check "${ver1Back}" "${ver2Back}"
		
		return ${?}
	else
		[[ "${1}" -gt "${2}" ]] && return 11 || return 9
	fi
}

function __main__ () {
	# ${1}: minOS
	# returns: version check code if min OS requirement is made
	
	local versCheck=""
	local osVersion=""
																							# get the current OS version
	osVersion=$(sw_vers -productVersion)
																							# exit if this is not the minimum OS or later	
	version_Check "${@}" "${osVersion}"
																							# get the result returned by version_Check
	versCheck=${?}

	case ${versCheck} in
		11 )
			. "_echoMsg.sh" ""
			. "_echoMsg.sh" "macOS ${1} is NOT supported"
			. "_echoMsg.sh" "Exiting"
			. "_echoMsg.sh" ""
			
			# display dialog?
	
			exit 1
		;;
	esac
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.1, 02-24-2017


__main__ "${@}"