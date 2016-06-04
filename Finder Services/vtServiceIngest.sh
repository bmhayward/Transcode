#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/private/tmp/transcodeServiceIngestTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	vtServiceIngest
#	Copyright (c) 2016 Brent Hayward
#		
#	
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.9, 05-19-2016"
	
	loggerTag="transcode.serviceIngest"
	
	readonly libDir="${HOME}/Library"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")						# get the path to the Transcode folder
	
	readonly prefPath="${workDir}/Prefs.txt"
	readonly confPath="${libDir}/MakeMKV/settings.conf"
	readonly watchPath="${passedArgs[0]}"																		# get the watch folder launch agent
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	
	pathsMatched="false"																						# ingest and output (plex) path do not match
	icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"									# get the path to the custom icns file for Transcode
	
	readonly sh_readPrefs="${appScriptsPath}/_readPrefs.sh"
	readonly sh_writePrefs="${appScriptsPath}/_writePrefs.sh"
}

function update_Prefs () {
																				# if Prefs.txt does not exist, create it
	if [ ! -e "${prefPath}" ]; then
	   . "${sh_writePrefs}" "${prefPath}"
	fi
	
	. "${sh_readPrefs}" "${prefPath}"											# read in the preferences from Prefs.txt
			
	if [ "${plexPath}" != "${watchPath}" ]; then
		rm -f "${prefPath}"														# remove Prefs.txt
	else
		pathsMatched="true"														# ingest and output (plex) paths match
	fi	
	
	if [ "${pathsMatched}" == "false" ] && [ "${#passedArgs[@]}" -eq 1 ]; then
		. "${sh_writePrefs}" "${prefPath}" "${outExt}" "${deleteWhenDone}" "${movieTag}" "${tvTag}" "${convertedTag}" "${renameFile}" "${movieFormat}" "${tvShowFormat}" "${plexPath}" "${sshUser}" "${rsyncPath}" "${passedArgs[0]}" "${extrasTag}" "${outQuality}" "${tlaApp}"
	fi
}

function array_Contains () {
	# ${1}: array to search
	# ${2}: search term
	# Returns: array index if found
	
    local array="$1[@]"
    local seeking=${2}
    local loopCounter=0
	local returnIndex=-1
	
    for element in "${!array}"; do
        if [[ "${element}" == *"${seeking}"* ]]; then
			returnIndex=${loopCounter}
            break
        fi
		((loopCounter++))
    done

    echo ${returnIndex}
}

function update_Plist () {
		local plistBuddy="/usr/libexec/PlistBuddy"
		local plistDir="${libDir}/LaunchAgents"
		local plistName="com.videotranscode.ingest.watchfolder"
		local plistFile="${plistDir}/${plistName}.plist"

		if [ ! -e "${plistFile}" ]; then																					
																															# write out the watch folder LaunchAgent plist to ~/Library/LaunchAgent
			${plistBuddy} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
			${plistBuddy} -c 'Add :ProgramArguments array' "${plistFile}"
			${plistBuddy} -c 'Add :ProgramArguments:0 string "'"${libDir}/Application Scripts/com.videotranscode.transcode/watchFolder_ingest.sh"'"' "${plistFile}"
			${plistBuddy} -c 'Add :RunAtLoad bool true' "${plistFile}"
			${plistBuddy} -c 'Add :WatchPaths array' "${plistFile}"
			${plistBuddy} -c 'Add :WatchPaths:0 string "'"${passedArgs[0]}"'"' "${plistFile}"

			chmod 644 "${plistFile}"
		else
			launchctl unload "${plistFile}" > /dev/null 2>&1 | logger -t "${loggerTag}"										# unload the watch folder agent
			
			${plistBuddy} -c 'Set :WatchPaths:0 "'"${passedArgs[0]}"'"' "${plistFile}"										# update the launchAgent plist
		fi
		
		launchctl load "${plistFile}" 2>&1 | logger -t "${loggerTag}"														# load the launchAgent
}

function update_MKV () {
	local newPath="${passedArgs[0]}"
	local msgTxt="Ingest path updated to:\n$newPath"

	if [ -e "${confPath}" ]; then		
		declare -a confArray

		let i=0
		while IFS='' read -r lineData || [[ -n "${lineData}" ]]; do					# read in the preferences from the conf file
		    confArray[i]="${lineData}"
		    ((++i))
		done < "${confPath}"
		
		foundIndex=$(array_Contains confArray "app_DestinationDir")					# find the ingest path in the conf file
		
		if [ "${foundIndex}" -ne "-1" ]; then
			local replaceValue="\"${passedArgs[0]}\""								# replace the old ingest path with the new ingest path
			confArray[${foundIndex}]="app_DestinationDir = ${replaceValue}"			# update the array
			
			rm -f "${confPath}"														# remove the old conf file
			printf '%s\n' "${confArray[@]}" >> "${confPath}"						# create the new conf file
																					# if MakeMKV is running			
			if ( ps aux | grep "MakeMKV" |grep -v grep > /dev/null ); then
				local msgTxt="Quit and re-open MakeMKV to update the ingest path"
			fi
		fi	
	fi
	
cat << EOF | osascript -l AppleScript > /dev/null
set iconPath to "$icnsPath" as string
set posixPath to POSIX path of iconPath
set hfsPath to POSIX file posixPath

display dialog "$msgTxt" buttons {"OK"} default button "OK" with title "Transcode" with icon file hfsPath
EOF
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

declare -a passedArgs

passedArgs=("${@}")

define_Constants

update_Prefs

if [ "${pathsMatched}" == "false" ] && [ "${#passedArgs[@]}" -eq 1 ]; then
	update_Plist
	update_MKV	
else
	msgTxt="Please select a different ingest folder"
cat << EOF | osascript -l AppleScript > /dev/null
set iconPath to "$icnsPath" as string
set posixPath to POSIX path of iconPath
set hfsPath to POSIX file posixPath

display dialog "$msgTxt" buttons {"OK"} default button "OK" with title "Transcode" with icon file hfsPath
EOF
fi

exit 0