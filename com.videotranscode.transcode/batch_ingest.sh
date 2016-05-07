#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/batch_ingestTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_ingest		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a wrapper to Don Melton's batch script which transcodes DVD and Blu-Ray content.
#	https://github.com/donmelton/video_transcoding
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.4, 04-23-2016"
	
	readonly outDir="${workDir}/Convert"
	
	readonly queuePath="${workDir}/queue_ingest.txt"							# workDir is global, from watchFolder_ingest
	readonly workingPath="${libDir}/Preferences/${workingPlist}"				# workingPlist is global, from watchFolder_ingest
	# ingestPath is global, from watchFolder_ingest
	# workDir is global, from watchFolder_ingest
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"									# echo to the Terminal
	fi
    echo "${1}" 2>&1 | logger -t batch.ingest		# echo to syslog
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

function pre_Processors () {
	echo_Msg "Pre-processing files"
	local fileNameExt=""
	local queueValue=""
	
	for i in "${convertFiles[@]}"; do	
		fileNameExt=${i##*/}										# filename with extension
	
		queueValue="${ingestPath}/${fileNameExt}"
		echo ${queueValue} >> "${queuePath}"						# write the file path to the queue file
	done
}

function ingest_Process () {
	local showTitle=""
	
	input="$(sed -n 1p "${queuePath}")"														# get the first file to convert

	while [ "${input}" ]; do
		showTitle="${input##*/}"															# get the title of the video including extension

	 	sed -i '' 1d "${queuePath}" || exit 1  												# delete the line from the queue file										

		mv -f "${ingestPath}/${showTitle}" "${outDir}"										# transfer ingested files to the /Transcode/Convert directory
		rm -f "${ingestPath}/${showTitle}"													# need to remove the file from ingest

		input="$(sed -n 1p "${queuePath}")"													# get the next file to process
	done	
}

function clean_Up () {
																							# delete the semaphore file so processing can be started again
	rm -f "${workingPath}"
																							# process was halted, need to remove the last file and log that was not finished transcoding
	if [ ! -z "${input}" ]; then		
		# osascript -e 'display notification with title "Ingest Cancelled"'
		terminal-notifier -title "Ingest Cancelled" -activate com.apple.Terminal
	fi
																							# remove the queue file
	if [ -e "${queuePath}" ]; then
	    rm -f "${queuePath}"
	fi
}

function __main__ () {
																							# exit if no files to convert
	if [ ${#convertFiles[@]} -gt 0 ] && [ "${convertFiles[0]}" == "${ingestPath}/*" ]; then
		input=""
		echo_Msg ""
		echo_Msg "Exiting, no files found in ${ingestPath} to ingest."

		exit 1
	fi	
	
	pre_Processors
	ingest_Process
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap 'if_Error ${LINENO} $?' ERR															# trap errors

define_Constants

touch "${workingPath}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles
convertFiles=( "${ingestPath}"/* )												   			# get a list of filenames with path to convert

__main__

exit 0