#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/updateTranscodePostTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscodePost		
#	Copyright (c) 2016-2017 Brent Hayward		
#
#
#	This script runs after updateTranscode as a mechanism to update items outside of updateTranscodes responsbilities
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.3.4, 03-31-2017"
	
	loggerTag="transcode.post-update"
		
	# From updateTranscode:
		# readonly LIBDIR="${HOME}/Library"
		# readonly APPSCRIPTSPATH="/usr/local/Transcode"
		# readonly WORKDIR=$(aliasPath "${LIBDIR}/Application Support/Transcode/Transcode alias")
		# readonly VERSCURRENT=$(${PLISTBUDDY} -c 'print :CFBundleShortVersionString' "${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
		# readonly PLISTBUDDY="/usr/libexec/PlistBuddy"
		# readonly PREFDIR="${LIBDIR}/Preferences"
		# fullUpdate - true of false
		# SHA256Clean - true or false
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
	local waitingPlist=""
	local onHoldPlist=""
	local workingPlist=""
	local capturedOutput=""
	local postPath=""
	local fileName=""
	local i=""
	
	waitingPlist="{PREFDIR}/com.videotranscode.batch.waiting.plist"
	onHoldPlist="{PREFDIR}/com.videotranscode.batch.onhold.plist"
	workingPlist="{PREFDIR}/com.videotranscode.batch.working.plist"

	if [[ "${fullUpdate}" == "true" ]] && [[ ! -e "${waitingPlist}" || ! -e "${onHoldPlist}" || ! -e "${workingPlist}" ]]; then
		. "_echoMsg.sh" "Starting full update..." ""
		. "_sendNotification.sh" "Transcode Update" "Starting full update..."

		postPath=$(mktemp -d "/tmp/transcodeFullUpdate_XXXXXXXXXXXX")
																							# move the compressed resources to /tmp
		ditto "${APPSCRIPTSPATH}/Transcode Setup Assistant.app/Contents/Resources/vtExtras.zip" "${postPath}"
		ditto "${APPSCRIPTSPATH}/Transcode Setup Assistant.app/Contents/Resources/vtScripts.zip" "${postPath}"
																							# decompress the resources
		unzip "${postPath}/vtExtras.zip" -d "${postPath}/Extras" >/dev/null
		unzip "${postPath}/vtScripts.zip" -d "${postPath}/Scripts" >/dev/null

		declare -a extrasFiles_a
		
		extrasFiles_a[0]="Settings.app"
		extrasFiles_a[1]="Log Analyzer.app"
																							# loop through Extras looking for diffs
		for i in "${extrasFiles_a[@]}"; do
																							# is it different
			capturedOutput=$(diff --brief "${postPath}/${i}" "${WORKDIR}/${i}")
		
			if [[ "${capturedOutput}" == *"differ"* ]]; then
																							# move and rename the diff script to /Transcode/Extras
				ditto "${postPath}/${i}" "${WORKDIR}/${i}"
		
				. "_echoMsg.sh" "==> Updated ${i}" ""
			fi
		done
																							# loop through Scripts looking for diffs	
		declare -a scriptFiles_a
		declare -a libFiles_a
		
		scriptFiles_a=( "${postPath}/Scripts"/* )											# get a list of filenames with path

		for i in "${scriptFiles_a[@]}"; do
			fileName="${i##*/}"
																							# only look for non-library scripts
			if [[ "${fileName##*.}" == "sh" ]] && [[ "${fileName}" != "_"* ]]; then
																							# is it different
				capturedOutput=$(diff --brief "${i}" "${APPSCRIPTSPATH}/${fileName}")
	
				if [[ "${capturedOutput}" == *"differ"* ]]; then
																							# copy the diff script to /usr/local/Transcode
					ditto "${i}" "${APPSCRIPTSPATH}"

					. "_echoMsg.sh" "==> Updated ${fileName}" ""
				fi
			elif [[ "${fileName}" == "_"* ]]; then
																							# add this file to the array for future processing
				libFiles_a+=("${i}")
			fi
		done
																							# loop through the Library scripts
		for i in "${libFiles_a[@]}"; do
			fileName="${i##*/}"
			
			capturedOutput=$(diff --brief "${i}" "${APPSCRIPTSPATH}/Library/${fileName}")		
			
			if [[ "${capturedOutput}" == *"differ"* ]]; then
																							# copy the diff script to /usr/local/Transcode/Library
				ditto "${i}" "${APPSCRIPTSPATH}/Library"

				. "_echoMsg.sh" "==> Updated ${fileName}" ""
			fi
		done

		. "_echoMsg.sh" "Full update complete." ""
		. "_sendNotification.sh" "Transcode Update" "Full update completed"
																							# delete full update directory from /tmp
		rm -rf "${postPath}"
	fi
}

function patch_Update () {
	local capturedOutput=""
	local plistDir=""
	local plistName=""
	local plistFile=""
	local filePath=""
	
	plistDir="${LIBDIR}/LaunchAgents"
	plistName="com.videotranscode.gem.check"
	plistFile="${plistDir}/${plistName}.plist"

	case "${VERSCURRENT}" in
		"1.4.1" )
			. "_sendNotification.sh" "Transcode Update" "Modifying ${plistName}"
			
			launchctl unload "${plistFile}" > /dev/null 2>&1 | logger -t "${loggerTag}"		# unload launchAgent
																							# update the plist
			${PLISTBUDDY} -c 'Set :Disabled false' "${plistFile}"
			${PLISTBUDDY} -c 'Set :RunAtLoad bool false' "${plistFile}"
			${PLISTBUDDY} -c 'Add :StartCalendarInterval array' "${plistFile}"
			${PLISTBUDDY} -c 'Add :StartCalendarInterval:0:Hour integer 9' "${plistFile}"
			${PLISTBUDDY} -c 'Add :StartCalendarInterval:1:Minute integer 5' "${plistFile}"

			launchctl load "${plistFile}" 2>&1 | logger -t "${loggerTag}"					# load the launchAgent
		;;
		
		"1.4.5" )
			capturedOutput=$(diff --brief "${WORKDIR}/batch.command" "${APPSCRIPTSPATH}/Transcode Setup Assistant.app/Contents/Resources/batch.sh")

			if [[ "${capturedOutput}" == *"differ"* ]]; then
																							# update with the current version of batch.command
				mv -f "${APPSCRIPTSPATH}/Transcode Setup Assistant.app/Contents/Resources/batch.sh" "${WORKDIR}/batch.command"
				
				. "_echoMsg.sh" "==> Updated batch.command" ""
			fi
		;;
		
		"1.4.8" )
			filePath="/tmp/transcodePostUpgrade.sh"
			
																							# create a shell script
cat <<EOT >> ${filePath}
#!/usr/bin/env bash

echo ""
echo "========================================================================="
echo "Transcode Update - Terminal-Notifier"
echo ""
echo "This update will move Terminal-Notifer from a gem to a brew installation. This will allow for simplified future updating of Terminal-Notifier."
echo ""

sudo gem uninstall terminal-notifier

brew install terminal-notifier

srm "$0"

exit 0
EOT

			chmod u+x ${filePath}															# make the shell script executable

			batchCMD="${filePath}"

			open -a Terminal.app ${batchCMD}												# run the shell script from the Terminal to get user approval to complete
		;;
	esac																						
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
define_Constants

if [[ "${SHA256Clean}" == "true" ]]; then
	full_Update																				# does Transcode need a full update?
	patch_Update																			# apply and release specific patches
fi