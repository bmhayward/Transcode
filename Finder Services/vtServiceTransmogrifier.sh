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
	local versStamp="Version 1.0.1, 05-19-2016"
	
	readonly loggerTag="transcode.service"
	
	readonly libDir="${HOME}/Library"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")					# get the path to the Transcode folder
	
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"

	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"	
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
					. "${sh_echoMsg}" ""
					. "${sh_echoMsg}" "Transmogrifying ${file##*/}"
					convert-video "${file##*/}" 2>&1 | logger -t "${loggerTag}"
				fi
			fi
		done
	else
														# single file, apply
		fileExt="${searchPath##*.}"
														# only deal with .m4v, .mp4 or .mkv files
		if [[ "${fileExt}" = "m4v" || "${fileExt}" = "mp4" || "${fileExt}" = "mkv" ]]; then
			cd "${searchPath%/*}"
			
			. "${sh_echoMsg}" ""
			. "${sh_echoMsg}" "Transmogrifying ${searchPath##*/}"
			convert-video "${searchPath##*/}" 2>&1 | logger -t "${loggerTag}"
		fi
	fi

	. "${sh_echoMsg}" ""
done

exit 0