#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/service_TransmogrifierTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	service_Transmogrifier
#	Copyright (c) 2016-2017 Brent Hayward
#		
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.9, 02-14-2017"
	
	loggerTag="transcode.serviceTransmogrify"
	
	readonly LIBDIR="${HOME}/Library"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

define_Constants

for f in "${@}"; do
	searchPath="${f}" 																		# get the path passed by Automator

	if [[ -d "${searchPath}" ]]; then
																							# directory|directories, apply to each file
		cd "${searchPath}" || exit 1
	
		find . -print0 | while IFS= read -r -d '' file
		do
		   if [[ "${file##*/}" != "." && "${file##*/}" != ".DS_Store" && ! -d "${file}" ]]; then
				fileExt="${file##*.}"
																							# only deal with .m4v, .mp4 or .mkv files
				if [[ "${fileExt}" == "m4v" || "${fileExt}" == "mp4" || "${fileExt}" == "mkv" ]]; then
					. "_echoMsg.sh" ""
					. "_echoMsg.sh" "Transmogrifying ${file##*/}"
					convert-video "${file##*/}" 2>&1 | logger -t "${loggerTag}"
				fi
			fi
		done
	else
																							# single file, apply
		fileExt="${searchPath##*.}"
																							# only deal with .m4v, .mp4 or .mkv files
		if [[ "${fileExt}" == "m4v" || "${fileExt}" == "mp4" || "${fileExt}" == "mkv" ]]; then
			cd "${searchPath%/*}" || exit 1
			
			. "_echoMsg.sh" ""
			. "_echoMsg.sh" "Transmogrifying ${searchPath##*/}"
			convert-video "${searchPath##*/}" 2>&1 | logger -t "${loggerTag}"
		fi
	fi

	. "_echoMsg.sh" ""
done

exit 0