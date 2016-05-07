#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:${HOME}/Library/Scripts export PATH

# set -xv ; exec 1>>/private/tmp/transcodeLogAnalysis1TraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	logAnalysis_Part1
#	Copyright (c) 2016 Brent Hayward
#		
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.6, 04-30-2016"
	
	readonly libDir="${HOME}/Library"
	
	if [ -e "/usr/local/bin/aliasPath" ]; then
		readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")					# get the path to the Transcode folder
	else
		readonly workDir=""
	fi
	
	readonly logsPath=$(mktemp -d "/tmp/transcodeLogAnalysis_XXXXXXXXXXXX")										# create a temp directory to hold the analysis
	readonly icnsPath="${scriptDir}/AutomatorApplet.icns"
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"												# echo to the Terminal
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
	
	local datePath="${logsPath}/dateCreated.txt"

	echo_Msg "" ""
	declare -a convertFiles
	convertFiles=( "${1}"/* )													 		# get a list of filenames with path to convert

	cd "${1}"																			# move to the /Transcode/Logs

	echo_Msg "Preparing log data..." ""
	for i in "${convertFiles[@]}"; do 													# get a list of the log files
		fileInfo=$(GetFileInfo -d "${i}")												# get the date/time created
		
		i="${i%.*}"																		# strip .log off the filename
		echo "${fileInfo}"" ""${i##*/}" >> "${datePath}"								# write out the file
	done
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

trap 'if_Error ${LINENO} $?' ERR														# trap errors

define_Constants

path2Process=""
	
if [ "$#" -ne 0 ]; then
	for f in "${@}"; do
		searchPath="${f}" 																# get the path passed by Automator

		if [ -d "${searchPath}" ] && [ "$#" -eq 1 ]; then
																						# directory
			path2Process="${searchPath}"
													
		else
																						# single files, copy to temp directory
			if [ -z "${path2Process}" ]; then
				path2Process=$(mktemp -d "/tmp/logs2Analyze_XXXXXXXXXXXX")
			fi																			
																						# copy the file to the a temp directory to hold for analysis
			cp -a -- "${searchPath}" "${path2Process}/${searchPath##*/}"
		fi

		echo_Msg "" ""
	done
else
	path2Process="${workDir}/Logs"
fi

analyzeLogs "${path2Process}"
																						# return the log path
echo "${logsPath}#${path2Process}"