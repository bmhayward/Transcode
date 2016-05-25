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
	local versStamp="Version 1.0.6, 05-23-2016"
	
	loggerTag="batch.ingest"
	
	readonly outDir="${workDir}/Convert"
	
	readonly queuePath="${workDir}/queue_ingest.txt"							# workDir is global, from watchFolder_ingest
	readonly workingPath="${libDir}/Preferences/${workingPlist}"				# workingPlist is global, from watchFolder_ingest
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_sendNotification="${appScriptsPath}/_sendNotification.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"

	# From watchFolder_ingest.sh
		# readonly ingestPath="${prefs[11]}"
		# readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")
		# readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
}

function pre_Processors () {
	. "${sh_echoMsg}" "Pre-processing files"
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
		. "${sh_sendNotification}" "Ingest Cancelled"
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
		. "${sh_echoMsg}" ""
		. "${sh_echoMsg}" "Exiting, no files found in ${ingestPath} to ingest."

		exit 1
	fi	
	
	pre_Processors
	ingest_Process
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

define_Constants

touch "${workingPath}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles
convertFiles=( "${ingestPath}"/* )												   			# get a list of filenames with path to convert

__main__

exit 0