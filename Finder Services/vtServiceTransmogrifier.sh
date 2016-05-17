#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/private/tmp/transcodeServiceTransmogrifierTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	vtServiceTransmogrifier
#	Copyright (c) 2016 Brent Hayward
#		
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.0, 05-16-2016"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

define_Constants

for f in "${@}"; do
	searchPath="${f}" 									# get the path passed by Automator

	if [ -d "${searchPath}" ]; then
														# directory|directories, apply to each file
		cd "${searchPath}"
	
		find . -print0 | while IFS= read -r -d '' file
		do
		   if [[ "${file##*/}" != "." && "${file##*/}" != ".DS_Store" && ! -d "${file}" ]]; then
				fileExt="${file##*.}"
														# only deal with .m4v, .mp4 or .mkv files
				if [[ "${fileExt}" = "m4v" || "${fileExt}" = "mp4" || "${fileExt}" = "mkv" ]]; then
					echo "" 2>&1 | logger -t transcode.service
					echo "Transmogrifying ${file##*/}" 2>&1 | logger -t transcode.service
					convert-video "${file##*/}" 2>&1 | logger -t transcode.service
				fi
			fi
		done
	else
														# single file, apply
		fileExt="${searchPath##*.}"
														# only deal with .m4v, .mp4 or .mkv files
		if [[ "${fileExt}" = "m4v" || "${fileExt}" = "mp4" || "${fileExt}" = "mkv" ]]; then
			cd "${searchPath%/*}"
			
			echo "" 2>&1 | logger -t transcode.service
			echo "Transmogrifying ${searchPath##*/}" 2>&1 | logger -t transcode.service
			convert-video "${searchPath##*/}" 2>&1 | logger -t transcode.service
		fi
	fi

	echo "" 2>&1 | logger -t transcode.service
done

exit 0