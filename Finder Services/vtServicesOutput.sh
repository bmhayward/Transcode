#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/transcodeServiceOutputTraceLog 2>&1

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	vtServicesOutput
#	Copyright (c) 2016 Brent Hayward
#		
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.0, 05-18-2016"
	
	readonly libDir="${HOME}/Library"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")		# get the path to the Transcode folder
	
	readonly prefPath="${workDir}/Prefs.txt"
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	
	readonly sh_readPrefs="${appScriptsPath}/_readPrefs.sh"
	readonly sh_writePrefs="${appScriptsPath}/_writePrefs.sh"
	
	pathsMatched="false"																		# ingest and output (plex) path do not match
}

function update_Prefs () {
	local icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"	# get the path to the custom icns file for Transcode
	local outDest="${passedArguments[0]}"
	local msgTxt="Output destination updated to:\n$outDest"
																					# if Prefs.txt does not exist, create it
	if [ ! -e "${prefPath}" ]; then
	   . "${sh_writePrefs}" "${prefPath}"
	fi
	
	. "${sh_readPrefs}" "${prefPath}"												# read in the preferences from Prefs.txt

	if [ "${ingestPath}" != "${outDest}" ]; then
		rm -f "${prefPath}"															# remove Prefs.txt
	else
		pathsMatched="true"															# ingest and output (plex) paths match
		msgTxt="Please select a different output destination"
	fi
	
	if [ "${pathsMatched}" == "false" ] && [ "${#passedArguments[@]}" -eq 1 ]; then
		. "${sh_writePrefs}" "${prefPath}" "${outExt}" "${deleteWhenDone}" "${movieTag}" "${tvTag}" "${convertedTag}" "${renameFile}" "${movieFormat}" "${tvShowFormat}" "${passedArguments[0]}" "${sshUser}" "${rsyncPath}" "${ingestPath}" "${extrasTag}" "${outQuality}" "${tlaApp}"
	fi

cat << EOF | osascript -l AppleScript > /dev/null
set iconPath to "$icnsPath" as string
set posixPath to POSIX path of iconPath
set hfsPath to POSIX file posixPath

display dialog "$msgTxt" buttons {"OK"} default button "OK" with title "Transcode" with icon file hfsPath
EOF
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

define_Constants

declare -a passedArguments

passedArguments=("${@}")

update_Prefs

exit 0