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
	local versStamp="Version 1.1.9, 07-31-2016"
	
	loggerTag="transcode.post-update"
		
	# From updateTranscode:
		# readonly libDir="${HOME}/Library"
		# readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
		# readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")
		# readonly versCurrent=$(${plistBuddy} -c 'print :CFBundleShortVersionString' "${appScriptsPath}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
		# readonly plistBuddy="/usr/libexec/PlistBuddy"
		# readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
		# readonly sh_ifError="${appScriptsPath}/_ifError.sh"
		# fullUpdate - true of false
		# SHA1Clean - true or false
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
	local postPath=""
	local fileName=""
	local loopCounter=0

	if [[ "${fullUpdate}" == "true" ]] && [[ ! -e "${waitingPlist}" || ! -e "${onHoldPlist}" || ! -e "${workingPlist}" ]]; then
		. "${sh_echoMsg}" "Starting full update..." ""
		. "${sh_sendNotification}" "Transcode Update" "Starting full update..."

		postPath=$(mktemp -d "/tmp/transcodeFullUpdate_XXXXXXXXXXXX")
																							# move the compressed resources to /tmp
		ditto "${workDir}/Extras/Transcode Setup Assistant.app/Contents/Resources/vtExtras.zip" "${postPath}"
		ditto "${workDir}/Extras/Transcode Setup Assistant.app/Contents/Resources/vtScripts.zip" "${postPath}"
																							# decompress the resources
		unzip "${postPath}/vtExtras.zip" -d "${postPath}/Extras" >/dev/null
		unzip "${postPath}/vtScripts.zip" -d "${postPath}/Scripts" >/dev/null
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
			capturedOutput=$(diff --brief "${postPath}/Extras/${i}" "${workDir}/Extras/${cmdFiles[${loopCounter}]}")

			if [[ "${capturedOutput}" = *"differ"* ]]; then
																							# move and rename the diff script to /Transcode/Extras
				mv -f "${postPath}/Extras/${i}" "${workDir}/Extras/${cmdFiles[${loopCounter}]}"

				. "${sh_echoMsg}" "==> Updated ${cmdFiles[${loopCounter}]}" ""
			fi
	
			(( loopCounter++ ))
		done
																							# loop through Scripts looking for diffs	
		declare -a scriptFiles
		scriptFiles=( "${postPath}/Scripts"/* )												# get a list of filenames with path

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
																							# delete full update directory from /tmp
		rm -rf "${postPath}"
	fi
}

function patch_Update () {
	local capturedOutput=""
	local plistDir="${libDir}/LaunchAgents"
	local plistName="com.videotranscode.gemautoupdate"
	local plistFile="${plistDir}/${plistName}.plist"
																							# remove the old gem updater if present
	capturedOutput=$(launchctl unload "${plistFile}")
	if [[ "${capturedOutput}" != *"No such file or directory"* ]]; then
		rm -f "${plistFile}"
	fi
																							# install new gem updater if not present
	plistName="com.videotranscode.gem.check"
	plistFile="${plistDir}/${plistName}.plist"
																							
	if [ ! -e "${plistFile}" ]; then
		${plistBuddy} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		${plistBuddy} -c 'Add :Disabled bool true' "${plistFile}"
		${plistBuddy} -c 'Add :EnvironmentVariables dict' "${plistFile}"
		${plistBuddy} -c 'Add :EnvironmentVariables:PATH string /usr/local/bin:/usr/bin:/usr/sbin' "${plistFile}"
		${plistBuddy} -c 'Add :ProgramArguments array' "${plistFile}"
		${plistBuddy} -c 'Add :ProgramArguments:0 string "'"${appScriptsPath}/Transcode Updater.app/Contents/Resources/updateTranscodeGemsCheck.sh"'"' "${plistFile}"
		${plistBuddy} -c 'Add :RunAtLoad bool false' "${plistFile}"

		chmod 644 "${plistFile}"
		
		if[ "${versCurrent}" = "1.4.0" ]; then
																							# need to run updateTranscodeGemsCheck
			${plistBuddy} -c 'Set :Disabled false' "${plistFile}"
			launchctl load "${plistFile}" 2>&1 | logger -t "${loggerTag}"					# load the launchAgent
		fi
	fi
	
	case "${versCurrent}" in
		"1.4.1" )
			. "${sh_sendNotification}" "Transcode Update" "Modifying ${plistName}"
			
			launchctl unload "${plistFile}" > /dev/null 2>&1 | logger -t "${loggerTag}"	# unload launchAgent
																						# update the plist
			${plistBuddy} -c 'Set :Disabled false' "${plistFile}"
			${plistBuddy} -c 'Set :RunAtLoad bool false' "${plistFile}"
			${plistBuddy} -c 'Add :StartCalendarInterval array' "${plistFile}"
			${plistBuddy} -c 'Add :StartCalendarInterval:0:Hour integer 9' "${plistFile}"
			${plistBuddy} -c 'Add :StartCalendarInterval:1:Minute integer 5' "${plistFile}"

			launchctl load "${plistFile}" 2>&1 | logger -t "${loggerTag}"				# load the launchAgent
		;;
	esac																						
}

function __main__ () {
	define_Constants

	if [ "${SHA1Clean}" == "true" ]; then
		full_Update																			# does Transcode need a full update?
		patch_Update																		# apply and release specific patches
	fi
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
__main__