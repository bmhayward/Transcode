#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/tmp/updateTranscodePostTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodePost		
#	Copyright (c) 2016 Brent Hayward		
#
#
#	This script runs after updateTranscode as a mechanism to update items outside of updateTranscodes responsbilities
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.1, 06-25-2016"
	
	loggerTag="transcode.post-update"
	
	readonly comLabel="com.videotranscode.transcode"
	
	readonly libDir="${HOME}/Library"
	readonly prefDir="${libDir}/Preferences"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")
	
	readonly appScriptsPath="${libDir}/Application Scripts/${comLabel}"
	readonly updateTranscode="${libDir}/Preferences/${comLabel}.full.update.plist"
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	
	readonly plistBuddy="/usr/libexec/PlistBuddy"
	readonly versCurrent=$(${plistBuddy} -c 'print :CFBundleShortVersionString' "${appScriptsPath}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
	readonly gemUpdatePlist="com.videotranscode.gem.update.plist"
}

function runAndDisown () {
	# ${1}: path to script to execute

	if test -t 1; then
	  exec 1>/dev/null
	fi

	if test -t 2; then
	  exec 2>/dev/null
	fi

	"$@" &
}

function full_Update () {
	local waitingPlist="{prefDir}/com.videotranscode.batch.waiting.plist"
	local onHoldPlist="{prefDir}/com.videotranscode.batch.onhold.plist"
	local workingPlist="{prefDir}/com.videotranscode.batch.working.plist"
	local capturedOutput=""
	local updaterPath=""
	local fileName=""
	local loopCounter=0
	
	if [[ -e "${updateTranscode}" ]] && [[ ! -e "${waitingPlist}" || ! -e "${onHoldPlist}" || ! -e "${workingPlist}" ]]; then
		. "${sh_echoMsg}" "Starting full update..." ""
		
		updaterPath=$(mktemp -d "/tmp/transcodeFullUpdate_XXXXXXXXXXXX")
																							# move the compressed resources to /tmp
		ditto "${workDir}/Extras/Transcode Setup Assistant.app/Contents/Resources/vtExtras.zip" "${updaterPath}"
		ditto "${workDir}/Extras/Transcode Setup Assistant.app/Contents/Resources/vtScripts.zip" "${updaterPath}"
																							# decompress the resources
		unzip "${updaterPath}/vtExtras.zip" -d "${updaterPath}/Extras" >/dev/null
		unzip "${updaterPath}/vtScripts.zip" -d "${updaterPath}/Scripts" >/dev/null
																							# setup matching arrays to look for Extras
		declare -a cmdFiles
		cmdFiles[0]="setupIngestAutoConnect.command"
		cmdFiles[1]="setupDestinationAutoConnect.command"
		cmdFiles[2]="uninstallTranscode.command"

		declare -a extrasFiles
		extrasFiles[0]="sshSource.sh"
		extrasFiles[1]="sshDestination.sh"
		extrasFiles[2]="uninstallTranscode.sh"
																							# loop through Extras looking for diffs
		for i in "${extrasFiles[@]}"; do
																							# is it different
			capturedOutput=$(diff --brief "${updaterPath}/Extras/${i}" "${workDir}/Extras/${cmdFiles[${loopCounter}]}")
		
			if [[ "${capturedOutput}" = *"differ"* ]]; then
																							# move and rename the diff script to /Transcode/Extras
				mv -f "${updaterPath}/Extras/${i}" "${workDir}/Extras/${cmdFiles[${loopCounter}]}"

				. "${sh_echoMsg}" "==> Updated ${cmdFiles[${loopCounter}]}" ""
			fi
			
			(( loopCounter++ ))
		done
																							# loop through Scripts looking for diffs	
		declare -a scriptFiles
		scriptFiles=( "${updaterPath}/Scripts"/* )											# get a list of filenames with path
	
		for i in "${scriptFiles[@]}"; do
			fileName=${i##*/}
			
			if [ "${i##*.}" = "sh" ]; then
																							# is it different
				capturedOutput=$(diff --brief "${i}" "${appScriptsPath}/${fileName}")
			
				if [[ "${capturedOutput}" = *"differ"* ]]; then
																							# copy the diff script to ~/Library/Application Scripts/com.videotranscode.transcode
					ditto "${i}" "${appScriptsPath}"

					. "${sh_echoMsg}" "==> Updated ${fileName}" ""
				fi
			fi
		done
		
		. "${sh_echoMsg}" "Full update complete." ""
																							# delete full update resources from /tmp
		rm -rf "${updaterPath}"
																							# remove sempahore from ~/Library
		rm -f "${updateTranscode}"
	fi	
}

function patch_Update () {
	local plistName="com.videotranscode.gemautoupdate"
	local plistFile="${libDir}/LaunchAgents/${plistName}.plist"														# get the watch folder launch agent

	if [ ! -e "${plistFile}" ]; then																				# write out the watch folder LaunchAgent plist to ~/Library/LaunchAgent
		local watchPath="${libDir}/Preferences/${gemUpdatePlist}"													# get the path to the watch plist

		${plistBuddy} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		${plistBuddy} -c 'Add :ProgramArguments array' "${plistFile}"
		${plistBuddy} -c 'Add :ProgramArguments:0 string "'"${appScriptsPath}/Transcode Updater.app/Contents/Resources/updateTranscodeGemsCheck.sh"'"' "${plistFile}"
		${plistBuddy} -c 'Add :RunAtLoad bool true' "${plistFile}"
		${plistBuddy} -c 'Add :WatchPaths array' "${plistFile}"
		${plistBuddy} -c 'Add :WatchPaths:0 string "'"${watchPath}"'"' "${plistFile}"

		chmod 644 "${plistFile}"

		launchctl load "${plistFile}"																				# load the launchAgent
	
		. "${sh_echoMsg}" "Created and started launchAgent ${watchPath}..." ""
	fi
}

function clean_Up () {
																							# make sure all scripts are executable
	find "${appScriptsPath}/" -name "*.sh" -exec chmod +x {} \;
	find "${workDir}/" -name "*.command" -exec chmod +x {} \;
	find "${workDir}/Extras/" -name "*.command" -exec chmod +x {} \;
																							# remove any previous temp version
	if [ -e "/tmp/updateTranscode.sh" ]; then
		rm -f "/tmp/updateTranscode.sh"
	fi
																							# run updateTranscodeGemsCheck independently
	touch "${prefDir}/${gemUpdatePlist}"
}

function __main__ () {
	define_Constants

	full_Update																				# does Transcode need a full update?
	patch_Update																			# apply and release specific patches
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0