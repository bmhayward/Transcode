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
	local versStamp="Version 1.0.9, 04-08-2016"
	
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
	local outDest="${passedArgs[0]}"
	local msgTxt="Output destination updated to:\n$outDest"
	
	if [ -e "${prefPath}" ]; then		
		. "${sh_readPrefs}" "${prefPath}"											# read in the preferences from Prefs.txt
		
		if [ "${ingestPath}" != "${outDest}" ]; then
			rm -f "${prefPath}"														# remove Prefs.txt
		else
			pathsMatched="true"														# ingest and output (plex) paths match
			msgTxt="Please select a different output destination"
		fi
	else
		readonly outExt="mkv"														# get the transcode file extension
		readonly deleteWhenDone="false"												# what to do with the original files when done
		readonly movieTag="purple,Movie,VT"											# Finder tags for movie files
		readonly tvTag="orange,TV Show,VT"											# Finder tags for TV show files
		readonly convertedTag="blue,Converted"										# Finder tags for original files that have been transcoded		
		readonly renameFile="auto"													# whether or not to auto-rename files
		readonly movieFormat=""														# movie rename format
		readonly tvShowFormat="{n} - {'"'"'s'"'"'+s.pad(2)}e{e.pad(2)} - {t}"		# TV show rename format
		readonly plexPath=""														# where to put the transcoded files in Plex
		readonly sshUser=""															# get the ssh username
		readonly rsyncPath=""														# get the path to the rsync Remote directory
		readonly ingestPath=""														# get the path to the ingest directory
		readonly extrasTag="yellow,Extra,VT"										# Finder tags for Extra show files
		readonly outQuality=""														# Output quality setting to use
	fi
	
	if [ "${pathsMatched}" == "false" ] && [ "${#passedArgs[@]}" -eq 1 ]; then
		. "${sh_writePrefs}" "${prefPath}" "${outExt}" "${deleteWhenDone}" "${movieTag}" "${tvTag}" "${convertedTag}" "${renameFile}" "${movieFormat}" "${tvShowFormat}" "${passedArgs[0]}" "${sshUser}" "${rsyncPath}" "${ingestPath}" "${extrasTag}" "${outQuality}"		
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

declare -a passedArgs

passedArgs=("${@}")

update_Prefs

exit 0