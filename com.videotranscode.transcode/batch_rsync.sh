#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/batch_rsyncTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	batch_rsync		
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite.
#	It is called by watchFolder_rsync.sh.
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	readonly versStamp="Version 1.5.4, 03-20-2017"
	
	loggerTag="batch.rsync"
		
	readonly WORKINGPLIST="com.videotranscode.rsync.batch.working.plist"
	
	readonly LIBDIR="${HOME}/Library"
	readonly WORKINGPATH="${LIBDIR}/Preferences/${WORKINGPLIST}"
																							# sets CONVERTDIR and WORKDIR variables
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"
	
	readonly OUTDIR="${CONVERTDIR}"
	readonly REMOTEDIR="/usr/local/Transcode/Remote"
	readonly QUEUEPATH="/tmp/queue_remote.txt"
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
}

function pre_Processors () {
	local fileNameExt=""
	local queueValue=""
	local i=""

	. "_echoMsg.sh" "Pre-processing files:"
	
	for i in "${convertFiles_a[@]}"; do
		. "_echoMsg.sh" "${i}"
		
		if [[ ! -d "${i}" ]]; then
			fileNameExt=${i##*/}															# filename with extension

			queueValue="${OUTDIR}/${fileNameExt}"
			echo "${queueValue}" >> "${QUEUEPATH}"											# write the file path to the queue file
		fi
	done
}

function rsync_Process () {
	local titleName=""
	local fileType=""
	local showTitle=""
	local renamedPath=""
	local msg=""
	local movieFormat_=""
	local tvFormat_=""
	local completedPath_=""
	local outExt_=""
	local prefValues=""
	local saveIFS=""
																							# read in the preferences
	prefValues=$(. "_readPrefs.sh" "${PREFPATH}" "MovieRenameFormat" "TVRenameFormat" "CompletedDirectoryPath" "OutputFileExt")

	declare -a keyValue_a

	saveIFS=${IFS}
	IFS=':' read -r -a keyValue_a <<< "${prefValues}" 										# convert string to array based on :
	IFS=${saveIFS}																			# restore IFS

	movieFormat_="${keyValue_a[0]}"
	tvFormat_="${keyValue_a[1]}"
	completedPath_="${keyValue_a[2]}"
	outExt_="${keyValue_a[3]}"
	
	input="$(sed -n 1p "${QUEUEPATH}")"														# get the first file to convert

	while [[ "${input}" ]]; do
	    titleName="$(basename "${input}" | sed 's/\.[^.]*$//')" 							# get the title of the video, no file extension
		showTitle="${input##*/}"															# get the title of the video including extension
	    fileType="unknown"																	# file type is unknown
	    
		. "_echoMsg.sh" ""
		. "_echoMsg.sh" "Processing remote title: ${showTitle}"
		
	    if [[ "${titleName}" =~ ([s][0-9]+[e][0-9]+) ]]; then
   			fileType="tvshow"																# TV show
   		else
   			fileType="movie"																# Movie
   		fi

		. "_echoMsg.sh" "File type: ${fileType}"
  																							# delete the line from the queue file
	 	sed -i '' 1d "${QUEUEPATH}" || exit 1
		
		if [[ "${showTitle}" == *"^"* ]]; then
																							# skipped file
			msg="Moved ${showTitle} to ${OUTDIR%/*}/Completed/Originals"
																							# move the skipped file to /Originals
			mv -f "${REMOTEDIR}/${showTitle}" "${OUTDIR%/*}/Completed/Originals"
			
		elif [[ "${showTitle}" == *".log"* ]]; then
			msg="Moved ${showTitle} to ${OUTDIR%/*}/Logs"
																							# move the log file to /Logs
			mv -f "${REMOTEDIR}/${showTitle}" "${OUTDIR%/*}/Logs"
		
		elif [[ "${showTitle}" != *"${outExt_}"* ]]; then
			msg="Moved ${showTitle} to ${OUTDIR%/*}/Completed/Originals"

			. "_moveOriginal.sh" "${REMOTEDIR}/${showTitle}" "${OUTDIR%/*}/Completed/Originals"
			
		else
																							# renamed file with full path
			renamedPath="${REMOTEDIR}/${showTitle}"
			  																				# move the transcoded file to final location if flag is set
			renamedPath=$(. "_moveTranscoded.sh" "${renamedPath}" "${completedPath_}" "${movieFormat_}" "${tvFormat_}")
			
			msg="Moved ${showTitle} to ${renamedPath}"
		fi
		
		. "_echoMsg.sh" "${msg}"
	
		input="$(sed -n 1p "${QUEUEPATH}")"													# get the next file to process
	done	
}

function clean_Up () {
																							# delete the semaphore file so processing can be started again
	rm -f "${WORKINGPATH}"
																							# process was halted, need to remove the last file and log that was not finished transcoding
	if [[ ! -z "${input}" ]]; then		
		. "_sendNotification.sh" "Processing Cancelled"
	fi
																							# remove the queue file
	if [[ -e "${QUEUEPATH}" ]]; then
	    rm -f "${QUEUEPATH}"
	fi
}

function ___main___ {
	. "_echoMsg.sh" ""
																							# exit if no files to convert
	if [[ ${#convertFiles_a[@]} -gt 0 ]] && [[ "${convertFiles_a[0]}" == "${REMOTEDIR}/*" ]]; then
		input=""

		. "_echoMsg.sh" "Exiting, no files found in ${REMOTEDIR} to process."

		exit 1
	fi	

	pre_Processors
	rsync_Process	
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors

define_Constants

touch "${WORKINGPATH}"																		# set the semaphore file to put any additional processing on hold

declare -a convertFiles_a
convertFiles_a=( "${REMOTEDIR}"/* )												   			# get a list of filenames with path to convert

___main___

exit 0