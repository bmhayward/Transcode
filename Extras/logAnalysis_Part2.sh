#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:${HOME}/Library/Scripts export PATH

# set -xv ; exec 1>>/private/tmp/transcodeLogAnalysis2TraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	logAnalysis_Part2
#	Copyright (c) 2016 Brent Hayward
#		
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.7, 05-03-2016"
	
	readonly libDir="${HOME}/Library"
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"									# echo to the Terminal
	fi
    echo "${1}" 2>&1 | logger -t transcode.logAnalysis			# echo to syslog
}

function if_Error () {
	# ${1}: last line of error occurence
	# ${2}: error code of last command
	
	local lastLine="${1}"
	local lastErr="${2}"
																		# if lastErr > 0 then echo error msg and log
	if [[ ${lastErr} -eq 0 ]]; then
		echo_Msg ""
		echo_Msg "Something went awry :-("
		echo_Msg "Script error encountered $(date) in ${scriptName}.sh: line ${lastLine}: exit status of last command: ${lastErr}"
		echo_Msg "Exiting..."
		
		exit 1
	fi
}

function analyzeLogs () {
	# ${1}: log directory
	
	local TAB=$'\t'
	local fileInfo=""
	
	local timePath="${logsPath}/time.txt"
	local speedPath="${logsPath}/speed.txt"
	local bitratePath="${logsPath}/bitrate.txt"
	local ratePath="${logsPath}/rate.txt"
	local datePath="${logsPath}/dateCreated.txt"
	
	local speedCols="${logsPath}/speedCols.txt"
	local bitrateCols="${logsPath}/bitrateCols.txt"
	local rateCols="${logsPath}/rateCols.txt"
	local dateCols="${logsPath}/dateCols.txt"
	local timeCreatedCols="${logsPath}/timeCreatedCols.txt"
	
	local timeSorted="${logsPath}/timeSorted.txt"
	local speedSorted="${logsPath}/speedSorted.txt"
	local bitrateSorted="${logsPath}/bitrateSorted.txt"
	local rateSorted="${logsPath}/rateSorted.txt"
	local dateSorted="${logsPath}/dateSorted.txt"
	local timeCreatedSorted="${logsPath}/timeCreatedSorted.txt"
	
	local timeTab="${logsPath}/timeTab.txt"
	local speedTab="${logsPath}/speedTab.txt"
	local bitrateTab="${logsPath}/bitrateTab.txt"
	local rateTab="${logsPath}/rateTab.txt"
	local dateTab="${logsPath}/dateTab.txt"
	local timeCreatedTab="${logsPath}/timeCreatedTab.txt"
	
	local dateTimeJoined="${logsPath}/dateTimeJoined.txt"
	local dateTimeTimeJoined="${logsPath}/dateTimeTimeJoined.txt"
	local dateTimeTimeSpeedJoined="${logsPath}/dateTimeTimeSpeedJoined.txt"
	local dateTimeTimeSpeedBitrateJoined="${logsPath}/dateTimeTimeSpeedBitrateJoined.txt"
	
	local logAnalysis="${logsPath}/transcodeLogAnalysis.txt"
																							# analyze the logs
	echo_Msg "Analyzing logs..."
	export LC_ALL="en_US.UTF-8"
	query-handbrake-log t --tabular "${1}" > "${timePath}"
	query-handbrake-log s --tabular "${1}" > "${speedPath}"
	query-handbrake-log b --tabular "${1}" > "${bitratePath}"
	query-handbrake-log r --tabular "${1}" > "${ratePath}"	
																							# remove unneccessary columns
	echo_Msg "Deleting column data"
	cut -d " " -f 1,3- "${datePath}" > "${dateCols}"
	cut -d " " -f 2,3- "${datePath}" > "${timeCreatedCols}"
																							# sort by video title in ascending order
	echo_Msg "Sorting by video title"
	sort -k2 "${timePath}" > "${timeSorted}"
	sort -k2 "${speedPath}" > "${speedSorted}"
	sort -k2 "${bitratePath}" > "${bitrateSorted}"
	sort -k2 "${ratePath}" > "${rateSorted}"
	sort -k2 "${dateCols}" > "${dateSorted}"
	sort -k2 "${timeCreatedCols}" > "${timeCreatedSorted}"
																							# replace column delimiters with tabs	
	echo_Msg "Replacing column delimiters"
	cat "${dateSorted}" | sed 's/[[:space:]]/'"${TAB}"'/1' > "${dateTab}"
	cat "${timeCreatedSorted}" | sed 's/[[:space:]]/'"${TAB}"'/1' > "${timeCreatedTab}"
																							# merge the tab files into a single file
	echo_Msg "Merging files"
	join  -t "${TAB}" -1 2 -2 2 "${dateTab}" "${timeCreatedTab}" > "${dateTimeJoined}"
	join  -t "${TAB}" -1 1 -2 2 "${dateTimeJoined}" "${timeSorted}" > "${dateTimeTimeJoined}"
	join  -t "${TAB}" -1 1 -2 2 "${dateTimeTimeJoined}" "${speedSorted}" > "${dateTimeTimeSpeedJoined}"
	join  -t "${TAB}" -1 1 -2 2 "${dateTimeTimeSpeedJoined}" "${bitrateSorted}" > "${dateTimeTimeSpeedBitrateJoined}"
	join  -t "${TAB}" -1 1 -2 2 "${dateTimeTimeSpeedBitrateJoined}" "${rateSorted}" > "${logAnalysis}"
																							# put a header on the file
	echo 'Title'"${TAB}"'Created'"${TAB}"'@'"${TAB}"'time'"${TAB}"'speed (fps)'"${TAB}"'bitrate (kbps)'"${TAB}"'ratefactor' | cat - "${logAnalysis}" > temp && mv temp "${logAnalysis}"
	
	open -a Numbers.app "${logAnalysis}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

trap 'if_Error ${LINENO} $?' ERR															# trap errors

define_Constants

logsPath="${1%%#*}"
path2Process="${1##*#}"

analyzeLogs "${path2Process}"

exit 0