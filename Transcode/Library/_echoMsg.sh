#!/usr/bin/env bash

# PATH variable is set by the calling function!

# set -xv; exec 1>>/private/tmp/_echoMsgTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_echoMsg		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo (optional)
	# loggerTag is defined as global in the calling script
	
	declare -a colorCode_a

	colorCode_a[0]="[0m"		# noColor
	colorCode_a[1]="[1;36m"		# lightBlueBold
	colorCode_a[2]="[1;95m"		# lightMagentaBold
	colorCode_a[3]="[0;36m"		# lightBlue
	colorCode_a[4]="[0;95m"		# lightMagenta
	colorCode_a[5]="[1;32m"		# lightGreenBold
	colorCode_a[6]="[0;32m"		# lightGreen
	colorCode_a[7]="[1;93m"		# lightYellowBold
	colorCode_a[8]="[0;93m"		# lightYellow
	colorCode_a[9]="[1;37m"		# whiteBold
	colorCode_a[10]="[1;91m"	# redBold
	colorCode_a[11]="[0;91m"	# redPlain

	local lightBlueBold=$'\033'${colorCode_a[1]}
	local lightMagentaBold=$'\033'${colorCode_a[2]}
	local lightBlue=$'\033'${colorCode_a[3]}
	local lightMagenta=$'\033'${colorCode_a[4]}
	local lightGreen=$'\033'${colorCode_a[6]}
	local lightGreenBold=$'\033'${colorCode_a[5]}
	local lightYellow=$'\033'${colorCode_a[8]}
	local lightYellowBold=$'\033'${colorCode_a[7]}
	local whiteBold=$'\033'${colorCode_a[9]}
	local redPlain=$'\033'${colorCode_a[11]}
	local redBold=$'\033'${colorCode_a[10]}
	local noColor=$'\033'${colorCode_a[0]}	
	local msgTxt=""
	local charCount=""
	local logLocation=""
	local dateStamp=""
	
	logLocation="${HOME}/Library/Logs/Transcode.log"
	dateStamp=$(/bin/date +%Y-%m-%d\ %H:%M:%S)

	msgTxt="${1//%/%%}"																		# escape %
		
	if [[ $# -eq 1 ]]; then
		printf '%s\n' "${msgTxt}"															# echo to the Terminal
	fi
		
	if [[ "${1}" == *"${lightBlue:5}"* || "${1}" == *"${lightGreen:5}"* || "${1}" == *"${lightYellow:5}"* || "${1}" == *"${whiteBold:5}"* || "${1}" == *"${redPlain:5}"* || "${1}" == *"${lightBlueBold:5}"* || "${1}" == *"${lightGreenBold:5}"* || "${1}" == *"${lightYellowBold:5}"* || "${1}" == *"${redBold:5}"* || "${1}" == *"${lightMagenta:5}"* || "${1}" == *"${lightMagentaBold:5}"* ]]; then
		for i  in "${colorCode_a[@]}"; do
																							# strip out the color code
			msgTxt="${msgTxt//${i}}"
																							# find out how many color codes are left
			charCount=$(echo "${msgTxt}" | grep -o "\[" | wc -l)

			if [[ "${charCount}" -eq "0" ]]; then
																							# no color codes left, exit early
				break
			fi
		done
	fi
	
    printf '%s\n' "${msgTxt}" 2>&1 | logger -t "${loggerTag}"								# echo to syslog
	printf '%s  %s: %s\n' "${dateStamp}"  "${loggerTag}" "${msgTxt}" >> "${logLocation}"	# echo to ~/Library/Logs
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.1.9, 02-07-2017

if [[ $# -lt 1 ]]; then
	echo_Msg ""									# just echo a blank line
else
	echo_Msg "${@}"
fi