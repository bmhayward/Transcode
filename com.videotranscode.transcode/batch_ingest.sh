#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/batch_ingestTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_ingest		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite.
#	It is called by watchFolder_ingest.sh.
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.2.1, 03-06-2017"
	
	loggerTag="batch.ingest"
	
	readonly WORKINGPLIST="com.videotranscode.ingest.batch.working.plist"
	
	readonly LIBDIR="${HOME}/Library"
	readonly WORKINGPATH="${LIBDIR}/Preferences/${WORKINGPLIST}"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# sets CONVERTDIR and WORKDIR variables
	
	readonly OUTDIR="${CONVERTDIR}"
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
	readonly QUEUEPATH="/tmp/queue_ingest.txt"
	
	ingestPath_=$(. "_readPrefs.sh" "${PREFPATH}" "IngestDirectoryPath")					# read in the preferences from Prefs.plist
}

function pre_Processors () {
	local fileNameExt=""
	local queueValue=""
	local i=""
	
	. "_echoMsg.sh" ""
	. "_echoMsg.sh" "Pre-processing files:"
	
	for i in "${convertFiles_a[@]}"; do
		. "_echoMsg.sh" "${i}"
			
		fileNameExt=${i##*/}																# filename with extension
	
		queueValue="${ingestPath_}/${fileNameExt}"
		echo "${queueValue}" >> "${QUEUEPATH}"												# write the file path to the queue file
	done
}

function ingest_Process () {
	local showTitle=""
	
	. "_echoMsg.sh" ""
	. "_echoMsg.sh" "Ingesting files:"
	
	input="$(sed -n 1p "${QUEUEPATH}")"														# get the first file to convert

	while [[ "${input}" ]]; do
		. "_echoMsg.sh" "${input}"
		
		showTitle="${input##*/}"															# get the title of the video including extension

	 	sed -i '' 1d "${QUEUEPATH}" || exit 1  												# delete the line from the queue file										

		mv -f "${ingestPath_}/${showTitle}" "${OUTDIR}"										# transfer ingested files to the /Transcode/Convert directory
		rm -f "${ingestPath_}/${showTitle}"													# need to remove the file from ingest

		input="$(sed -n 1p "${QUEUEPATH}")"													# get the next file to process
	done	
}

function clean_Up () {
																							# delete the semaphore file so processing can be started again
	rm -f "${WORKINGPATH}"
																							# process was halted, need to remove the last file and log that was not finished transcoding
	if [[ ! -z "${input}" ]]; then
		. "_sendNotification.sh" "Ingest Cancelled"
	fi
																							# remove the queue file
	if [[ -e "${QUEUEPATH}" ]]; then
	    rm -f "${QUEUEPATH}"
	fi
}

function __main__ () {
																							# exit if no files to convert
	if [[ ${#convertFiles_a[@]} -gt 0 ]] && [[ "${convertFiles_a[0]}" == "${ingestPath_}/*" ]]; then
		input=""
		
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Exiting, no files found in ${ingestPath_} to ingest."

		exit 1
	fi	

	pre_Processors
	ingest_Process
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors

define_Constants

touch "${WORKINGPATH}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles_a
convertFiles_a=( "${ingestPath_}"/* )												   		# get a list of filenames with path to convert

__main__

exit 0