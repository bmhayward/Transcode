#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/transcode_SettingsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	transcode_Settings
#	Copyright (c) 2017 Brent Hayward
#
#	
#	This script sets the prefs.plist values for Transcode
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.3.0, 03-31-2017"
	
	loggerTag="transcode.settings"
		
	readonly LIBDIR="${HOME}/Library"
	readonly PLISTBUDDY="/usr/libexec/PlistBuddy"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"			# get the path to the Transcode folder, returns the WORKDIR and CONVERTDIR variable
	
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
	readonly CONFPATH="${LIBDIR}/MakeMKV/settings.conf"
	readonly PLISTBUDDY="/usr/libexec/PlistBuddy"

	outFileExt=""
	outputQuality=""
	setupAutoRename=""
	movieFormat=""
	tvFormat=""
	origTag=""
	movieTag=""
	tvTag=""
	extraTag=""
	logTag=""
	setupDeleteOrig=""
	setupDeleteRemote=""
	setupSSH="false"
	sshUserPref=""
	destAddr=""
	setupOutput="true"
	setupIngest="true"
	addAllAudio="false"
	audioWidth="stereo"
	prefsPlistTag=""
	ingestPath=""
	outputPath=""
	sshInfo=""
	prefCompletedPath=""
	prefIngestPath=""
	ingestPathsMatched=""
	resetIngest=""
	outputPathsMatched=""
	resetCompleted=""
	returnValue="false"
}

function pre_Process () {
	# ${1}: settings string
	
	local prefValues=""
	local saveIFS=""
	
	declare -a dialogSettings_a

	saveIFS=${IFS}
	IFS='|' read -r -a dialogSettings_a <<< "${@}"											# convert string to array based on |
	IFS=${saveIFS}																			# restore IFS
	
	outFileExt="${dialogSettings_a[0]}"
	outputQuality="${dialogSettings_a[1]}"
	addAllAudio="${dialogSettings_a[2]}"
	audioWidth="${dialogSettings_a[3]}"
	ingestPath="${dialogSettings_a[4]}"
	outputPath="${dialogSettings_a[5]}"
	movieFormat="${dialogSettings_a[6]}"
	tvFormat="${dialogSettings_a[7]}"
	setupAutoRename="${dialogSettings_a[8]}"
	origTag="${dialogSettings_a[9]}"
	movieTag="${dialogSettings_a[10]}"
	tvTag="${dialogSettings_a[11]}"
	extraTag="${dialogSettings_a[12]}"
	logTag="${dialogSettings_a[13]}"
	setupOutput="${dialogSettings_a[14]}"
	sshUserPref="${dialogSettings_a[15]}"
	destAddr="${dialogSettings_a[16]}"
	setupDeleteRemote="${dialogSettings_a[17]}"
	setupIngest="${dialogSettings_a[18]}"
																							# strip out any dashes
	outputQuality=$(echo "${outputQuality//-}")
	
	setupSSH="${setupOutput}"
	
	if [[ ! -z "${sshUserPref}" ]] && [[ ! -z "${destAddr}" ]]; then
		sshInfo="${sshUserPref}@${destAddr}"
	fi
																							# get the preference values before any potential change
	prefValues=$(. "_readPrefs.sh" "${PREFPATH}" "CompletedDirectoryPath" "IngestDirectoryPath")
	
	prefCompletedPath="${prefValues%%:*}"
	prefIngestPath="${prefValues##*:}"
}

function array_Contains () {
	# ${1}: array to search
	# ${2}: search term
	# Returns: array index if found
	
    local array=""
    local seeking=""
    local loopCounter=0
	local returnIndex=-1
	
	array="$1[@]"
    seeking="${2}"
	
    for element in "${!array}"; do
        if [[ "${element}" == *"${seeking}"* ]]; then
			returnIndex=${loopCounter}
            break
        fi
		((loopCounter++))
    done

    echo ${returnIndex}
}

function update_MKV () {
	local replaceValue=""
	
	if [[ -e "${CONFPATH}" ]]; then		
		declare -a confArray_a

		i=0
		while IFS='' read -r lineData || [[ -n "${lineData}" ]]; do							# read in the preferences from the conf file
		    confArray_a[i]="${lineData}"
		    ((++i))
		done < "${CONFPATH}"
		
		foundIndex=$(array_Contains confArray_a "app_DestinationDir")						# find the ingest path in the conf file
		
		if [[ "${foundIndex}" -ne "-1" ]]; then
			returnValue="true"
			replaceValue="\"${ingestPath}\""												# replace the old ingest path with the new ingest path
			confArray_a[${foundIndex}]="app_DestinationDir == ${replaceValue}"				# update the array
			
			rm -f "${CONFPATH}"																# remove the old conf file
			printf '%s\n' "${confArray_a[@]}" >> "${CONFPATH}"								# create the new conf file
			
			. "_echoMsg.sh" "Updated MakeMKV plist"
		fi
	fi
}

function sshSetup_Keys () {
	local installSSHKeys=""
	
	installSSHKeys="false"
																							# if necessary, create the .ssh directory
	if [[ ! -d "${HOME}/.ssh" ]]; then
		installSSHKeys="true"
		mkdir "${HOME}/.ssh"
		chmod 0700 "${HOME}/.ssh"
	fi
	
	if [[ "${installSSHKeys}" == "true" ]] || [[ ! -e "${HOME}/.ssh/id_rsa" || ! -e "${HOME}/.ssh/id_rsa.pub" ]]; then
																							# make sure no keys are hanging around
		rm -rf "${HOME}/.ssh/id_rsa*"

		cd "${HOME}/.ssh" || exit 1
																							# generate the public and private key pair, no feedback
		ssh-keygen -b 1024 -t rsa -f id_rsa -P "" -q
	fi
}

function sshCopyKeys2_Destination () {
	local installedBrews=""
	
	installedBrews=$(brew list)

	if [[ ${installedBrews} != *"ssh-copy-id"* ]]; then		
		. "_echoMsg.sh" "Installing brew ssh-copy-id"
	
		brew install ssh-copy-id
	fi
	
	ssh-copy-id "${sshInfo}"
}

function setup_Ingest () {
	local movedWorkingPlist=""
	local movedWorkingPath=""
	
	movedWorkingPlist="com.videotranscode.ingest.moved.working.plist"
	movedWorkingPath="${LIBDIR}/Preferences/${movedWorkingPlist}"
	ingestPathsMatched="false"																# ingest and completed path do not match
	resetIngest="false"																		# reset ingest path to default
																							# set the semaphore file to put any additional processing on hold
	touch "${movedWorkingPath}"
																							# write the original path to /Ingest to com.videotranscode.ingest.moved.working.plist
	printf '%s\n' "${prefIngestPath}" >> "${movedWorkingPath}"
	
	if [[ "${ingestPath}" == "${prefCompletedPath}" ]] || [[ "${ingestPath}" == "${prefIngestPath}" ]] || [[ "${ingestPath}" == *"${CONVERTDIR}"* ]]; then
																							# ingest and completed paths match
		ingestPathsMatched="true"
		
		if [[ "${ingestPath}" == "${CONVERTDIR}" ]] || [[ "${ingestPath}" == *"${CONVERTDIR}"* ]]; then
			resetIngest="true"
			ingestPath="${CONVERTDIR}"														# reset to default
		fi
	fi
	
	. "_echoMsg.sh" "Updated preference IngestDirectoryPath to ${ingestPath}"
																							# remove the Finder alias for the Ingest folder if it exists
	if [[ -e "${LIBDIR}/Application Support/Transcode/Ingest alias" ]]; then
		rm -f "${LIBDIR}/Application Support/Transcode/Ingest alias"
	fi

	if [[ "${ingestPathsMatched}" == "false" ]]; then
																							# make a Finder alias for the Ingest folder		
		. "_mkFinderAlias.sh" "${ingestPath}" "${LIBDIR}/Application Support/Transcode" "Ingest alias"
	fi
}

function setup_Output () {
	local movedWorkingPlist=""
	local movedWorkingPath=""
	
	movedWorkingPlist="com.videotranscode.completed.moved.working.plist"
	movedWorkingPath="${LIBDIR}/Preferences/${movedWorkingPlist}"
	outputPathsMatched="false"																# ingest and completed path do not match
	resetCompleted="false"																	# reset completed path to default
																							# set the semaphore file to put any additional processing on hold
	touch "${movedWorkingPath}"
																							# write the original path to /Completed to com.videotranscode.completed.moved.working.plist
	printf '%s\n' "${prefCompletedPath}" >> "${movedWorkingPath}"

	if [[ "${outputPath}" == "${ingestPath}" ]] || [[ "${outputPath}" == *"${WORKDIR}/Completed"* ]]; then
																							# ingest and completed paths match
		outputPathsMatched="true"
		
		if [[ "${outputPath}" == *"${WORKDIR}/Completed"* ]]; then
			resetCompleted="true"
			outputPath="${WORKDIR}/Completed"												# reset to default
		fi
	fi
	
	. "_echoMsg.sh" "Updated preference CompletedDirectoryPath to ${outputPath}"
																							# remove the Finder alias for the Completed folder if it exists
	if [[ -e "${LIBDIR}/Application Support/Transcode/Completed alias" ]]; then
		rm -f "${LIBDIR}/Application Support/Transcode/Completed alias"
	fi
	
	if [[ "${outputPathsMatched}" == "false" ]]; then
																							# make a Finder alias for the Completed folder		
		. "_mkFinderAlias.sh" "${outputPath}" "${LIBDIR}/Application Support/Transcode" "Completed alias"
	fi
}

function setup_RemoteOutput () {
																							# setup output to remote destination
	if [[ "${setupOutput}" == "true" ]]; then
 		if [[ ! -z "${sshUserPref}" ]] && [[ ! -z "${destAddr}" ]]; then
			sshSetup_Keys
			sshCopyKeys2_Destination
		else
			setupSSH="false"
			sshUserPref=""
			destAddr=""
			sshInfo=""
		fi
	fi
}

function setup_Destination () {
	local currentUser=""
	local remoteStatus=""
	
	currentUser=${USER}
																							# setup ingest from remote source
	if [[ ${setupIngest} == "true" ]]; then
		remoteStatus=$(sudo systemsetup -getremotelogin)
		
		if [[ "${remoteStatus}"  != *"On"* ]];then
			. "_echoMsg.sh" "Enabled Remote Login" ""
	
			sudo systemsetup -setremotelogin on
		fi

		if [[ ! -d "${HOME}/.ssh" ]]; then
			mkdir "${HOME}/.ssh"
			chown "${currentUser}" "${HOME}/.ssh"
			chmod 0700 "${HOME}/.ssh"
		fi
		
		if [[ ! -d "${LIBDIR}/LaunchAgents" ]]; then
																							# create LaunchAgents folder
			mkdir "${LIBDIR}/LaunchAgents"
		fi
		
		if [[ ! -d "/usr/local/Transcode/Remote" ]]; then
																							# create /Remote folder it does not exist
			mkdir "/usr/local/Transcode/Remote"
			
			chown "${currentUser}" "/usr/local/Transcode/Remote"
		fi
	fi
}

function update_Prefs () {
	local rsyncPathPref=""
	local plistFile=""
	local completedWatchPlist=""
	local plistDisabled=""
	 
	completedWatchPlist="com.videotranscode.completed.watchfolder.plist"
	plistFile="${LIBDIR}/LaunchAgents/${completedWatchPlist}"
	
	if [[ "${setupSSH}" == "true" ]]; then
																							# lookup the path to the /Transcode/Remote directory on the destination
		rsyncPathPref="/usr/local/Transcode/Remote"
	fi

	if [[ "${setupSSH}" == "false" ]]; then
		sshInfo=""
	fi
																							# update the preferences
	. "_writePrefs.sh" "${PREFPATH}" "OutputFileExt:${outFileExt}" "OutputQuality:${outputQuality}" "AddAllAudio:${addAllAudio}" "AudioWidth:${audioWidth}" "IngestDirectoryPath:${ingestPath}" "CompletedDirectoryPath:${outputPath}" "AutoRename:${setupAutoRename}" "MovieRenameFormat:${movieFormat}" "TVRenameFormat:${tvFormat}" "OriginalFileTags:${origTag}" "MovieTags:${movieTag}" "TVTags:${tvTag}" "ExtrasTags:${extraTag}" "LogTags:${logTag}" "DeleteAfterRemote:${setupDeleteRemote}" "sshUser:${sshInfo}" "RemoteDirectoryPath:${rsyncPathPref}"
	
	if [[ -e "${plistFile}" ]]; then
																							# ----------- stop com.videotranscode.completed.watchfolder.plist LaunchAgent -----------
		plistDisabled=$("${PLISTBUDDY}" -c 'print :Disabled' "${plistFile}")
		
		if [[ "${plistDisabled}" != *"true"* ]]; then
																							# unload the LaunchAgent
			launchctl unload -w "${plistFile}" 2>&1
			${PLISTBUDDY} -c 'Add :Disabled bool true' "${plistFile}"						# disable the LaunchAgent	
		fi
	fi

	. "_echoMsg.sh" "Updated preferences" ""
}

function update_IngestPlist () {
	local movedWorkingPlist=""
	local movedWorkingPath=""
	local plistDir=""
	local plistName=""
	local plistFile=""
	local plistDisabled=""
	local msgTxtLA=""
	local currentPlistPath=""
	
	movedWorkingPlist="com.videotranscode.ingest.moved.working.plist"
	movedWorkingPath="${LIBDIR}/Preferences/${movedWorkingPlist}"
	plistDir="${LIBDIR}/LaunchAgents"
	plistName="com.videotranscode.ingest.watchfolder"
	plistFile="${plistDir}/${plistName}.plist"
	msgTxtLA="No changes to"
																							# --------------- Ingest watch plist ---------------
	if [[ ! -e "${plistFile}" ]]; then
																							# write out the Ingest watch folder LaunchAgent plist to ~/Library/LaunchAgent
		${PLISTBUDDY} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		
		if [[ "${ingestPathsMatched}" == "true" ]]; then
				${PLISTBUDDY} -c 'Add :Disabled bool true' "${plistFile}"					# need to turn off, disable the LaunchAgent
		fi
		
		${PLISTBUDDY} -c 'Add :ProgramArguments array' "${plistFile}"
		${PLISTBUDDY} -c 'Add :ProgramArguments:0 string "'"/usr/local/Transcode/watchFolder_ingest.sh"'"' "${plistFile}"
		${PLISTBUDDY} -c 'Add :RunAtLoad bool true' "${plistFile}"
		${PLISTBUDDY} -c 'Add :WatchPaths array' "${plistFile}"
		${PLISTBUDDY} -c 'Add :WatchPaths:0 string "'"${ingestPath}"'"' "${plistFile}"
	
		chmod 644 "${plistFile}"
	else
																							# get the current path from the ingest watch plist
		currentPlistPath=$("${PLISTBUDDY}" -c 'print :WatchPaths' "${plistFile}")
																							# if the path from the plist does not match the path from ${ingestPath}, update
		if [[ "${currentPlistPath}" != *"{ingestPath}"* ]]; then
			plistDisabled=$("${PLISTBUDDY}" -c 'print :Disabled' "${plistFile}")
																							# unload the watch folder agent
			launchctl unload -w "${plistFile}" > /dev/null 2>&1 | logger -t "${loggerTag}"

			if [[ "${resetIngest}" == "true" ]]; then										# resetting to default Ingest location /Transcode/Convert
				if [[ "${plistDisabled}" != "true" ]];then
					msgTxtLA="Disabled"
					${PLISTBUDDY} -c 'Add :Disabled bool true' "${plistFile}"				# disable the LaunchAgent
				fi
			fi
		
			if [[ "${ingestPathsMatched}" == "false" ]]; then
				if [[ "${plistDisabled}" == "true" ]];then
					msgTxtLA="Updated"
				
					${PLISTBUDDY} -c 'Delete :Disabled bool' "${plistFile}"					# enable the LaunchAgent
																							# update the LaunchAgent plist
					${PLISTBUDDY} -c 'Set :WatchPaths:0 "'"${ingestPath}"'"' "${plistFile}"
																							# load the LaunchAgent		
					launchctl load -w "${plistFile}" 2>&1 | logger -t "${loggerTag}"
				fi
			fi
		fi
	fi
																							# remove the semaphore
	rm -f "${movedWorkingPath}"
	
	. "_echoMsg.sh" "${msgTxtLA} launchAgent ${plistFile}" ""
}

function update_OutputPlist () {
	local movedWorkingPlist=""
	local movedWorkingPath=""
	local plistDir=""
	local plistName=""
	local plistFile=""
	local plistDisabled=""
	local msgTxtLA=""
	local currentPlistPath=""
	
	movedWorkingPlist="com.videotranscode.completed.moved.working.plist"
	movedWorkingPath="${LIBDIR}/Preferences/${movedWorkingPlist}"
	plistDir="${LIBDIR}/LaunchAgents"
	plistName="com.videotranscode.completed.watchfolder"
	plistFile="${plistDir}/${plistName}.plist"
	plistDisabled=""
	msgTxtLA="No changes to"
																							# --------------- Completed watch plist ---------------
	if [[ ! -e "${plistFile}" ]]; then
																							# write out the Completed watch folder LaunchAgent plist to ~/Library/LaunchAgent
		${PLISTBUDDY} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		
		if [ "${outputPathsMatched}" == "true" ]; then
				${PLISTBUDDY} -c 'Add :Disabled bool true' "${plistFile}"					# need to turn off, disable the LaunchAgent
		fi
		
		${PLISTBUDDY} -c 'Add :ProgramArguments array' "${plistFile}"
		${PLISTBUDDY} -c 'Add :ProgramArguments:0 string "'"/usr/local/Transcode/watchFolder_completed.sh"'"' "${plistFile}"
		${PLISTBUDDY} -c 'Add :RunAtLoad bool true' "${plistFile}"
		${PLISTBUDDY} -c 'Add :WatchPaths array' "${plistFile}"
		${PLISTBUDDY} -c 'Add :WatchPaths:0 string "'"${outputPath}"'"' "${plistFile}"
	
		chmod 644 "${plistFile}"
	else
																							# get the current path from the completed watch plist
		currentPlistPath=$("${PLISTBUDDY}" -c 'print :WatchPaths' "${plistFile}")
																							# if the path from the plist does not match the path from ${outputPath}, update
		if [[ "${currentPlistPath}" != *"{outputPath}"* ]]; then
			plistDisabled=$("${PLISTBUDDY}" -c 'print :Disabled' "${plistFile}")
																							# unload the watch folder agent
			launchctl unload -w "${plistFile}" > /dev/null 2>&1 | logger -t "${loggerTag}"

			if [[ "${resetCompleted}" == "true" ]]; then									# resetting to default Completed location /Transcode/Completed
				if [[ "${plistDisabled}" != "true" ]];then
					msgTxtLA="Disabled"
					${PLISTBUDDY} -c 'Add :Disabled bool true' "${plistFile}"				# disable the LaunchAgent
				fi
			fi
		
			if [[ "${outputPathsMatched}" == "false" ]]; then
				if [[ "${plistDisabled}" == "true" ]];then
					msgTxtLA="Updated"
				
					${PLISTBUDDY} -c 'Delete :Disabled bool' "${plistFile}"					# enable the LaunchAgent
																							# update the LaunchAgent plist
					${PLISTBUDDY} -c 'Set :WatchPaths:0 "'"${outputPath}"'"' "${plistFile}"
																							# load the LaunchAgent		
					launchctl load -w "${plistFile}" 2>&1 | logger -t "${loggerTag}"
				fi
			fi
		fi
	fi
																							# remove the semaphore
	rm -f "${movedWorkingPath}"
	
	. "_echoMsg.sh" "${msgTxtLA} launchAgent ${plistFile}" ""
}

function update_DestPlist () {
	local watchPath=""
	local plistDir=""
	local plistName=""
	local plistFile=""
	local plistDisabled=""
	local msgTxtLA=""
	
	watchPath="/usr/local/Transcode/Remote"													# get the path to /Transcode/Remote
	plistDir="${LIBDIR}/LaunchAgents"
	plistName="com.videotranscode.rsync.watchfolder"
	plistFile="${plistDir}/${plistName}.plist"
	msgTxtLA="No changes to"
																							# --------------- rsync watch plist ---------------
	if [[ ! -e "${plistFile}" ]] && [[ "${setupIngest}" == "true" ]]; then
		msgTxtLA="Created"
																							# write out the rysnc watch folder LaunchAgent plist to ~/Library/LaunchAgent
		${PLISTBUDDY} -c 'Add :Label string "'"${plistName}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		${PLISTBUDDY} -c 'Add :ProgramArguments array' "${plistFile}"
		${PLISTBUDDY} -c 'Add :ProgramArguments:0 string "'"${APPSCRIPTSPATH}/watchFolder_rsync.sh"'"' "${plistFile}"
		${PLISTBUDDY} -c 'Add :RunAtLoad bool true' "${plistFile}"
		${PLISTBUDDY} -c 'Add :WatchPaths array' "${plistFile}"
		${PLISTBUDDY} -c 'Add :WatchPaths:0 string "'"${watchPath}"'"' "${plistFile}"
	
		chmod 644 "${plistFile}"
		
		launchctl load -w "${plistFile}" 2>&1 | logger -t "${loggerTag}"					# load the launchAgent
	else
		plistDisabled=$("${PLISTBUDDY}" -c 'print :Disabled' "${plistFile}")
		
		if [[ "${plistDisabled}" == "true" ]] && [[ "${setupIngest}" == "true" ]];then
			msgTxtLA="Enabled"
		
			${PLISTBUDDY} -c 'Delete :Disabled bool' "${plistFile}"							# enable the LaunchAgent
			
			launchctl load -w "${plistFile}" 2>&1 | logger -t "${loggerTag}"				# load the launchAgent
		elif [[ "${plistDisabled}" != "true" ]] && [[ "${setupIngest}" == "false" ]]; then
			msgTxtLA="Disabled"
			
			launchctl unload -w "${plistFile}" > /dev/null 2>&1 | logger -t "${loggerTag}"
			
			${PLISTBUDDY} -c 'Add :Disabled bool true' "${plistFile}"						# disable the LaunchAgent	
		fi
	fi

	. "_echoMsg.sh" "${msgTxtLA} launchAgent ${plistFile}" ""
	. "_echoMsg.sh" ""
}

function clean_Up () {
	if [[ "${setupSSH}" == "true" ]] && [[ "${setupIngest}" == "false" ]]; then
		prefsPlistTag="green,remote output destination"
																							# set the Finder tag indicating where the final output goes
		. "_finderTag.sh" "${prefsPlistTag}" "${WORKDIR}/Settings.app"
	elif [[ "${setupOutput}" == "false" ]] && [[ "${setupIngest}" == "true" ]]; then
																							# set the Finder tag indicating accepting content from remote source
		prefsPlistTag="orange,remote source content"
		. "_finderTag.sh" "${prefsPlistTag}" "${WORKDIR}/Settings.app"
	elif [[ "${setupOutput}" == "true" ]] && [[ "${setupIngest}" == "true" ]]; then
																							# set the Finder tag indicating both accepting content from remote source and indicating where the final output goes
		prefsPlistTag="green,remote output destination,orange,remote source content"
		. "_finderTag.sh" "${prefsPlistTag}" "${WORKDIR}/Settings.app"
	else
		prefsPlistTag="green,remote output destination,orange,remote source content"
																							# remove the Finder tags indicating where the final output goes
		tag --remove "${prefsPlistTag}" "${WORKDIR}/Settings.app"
	fi
	
	if [[ "${setupDeleteOrig}" == "true" ]]; then
		prefsPlistTag="red,delete original|"
		
		. "_finderTag.sh" "${prefsPlistTag}" "${WORKDIR}/Settings.app"
	else
																							# remove the Finder tags indicating where the final output goes
		prefsPlistTag="red,delete original"
		tag --remove "${prefsPlistTag}" "${WORKDIR}/Settings.app"
	fi
}

function ___main___ () {
	# ${1}: settings string, | delimited
	
	pre_Process "${@}"
																							# setup local ingest location
	setup_Ingest
	update_MKV
																							# setup the local output destination
	setup_Output
																							# setup SSH connections for delivery to remote destination
	setup_RemoteOutput
																							# update the prefs plist
	update_Prefs
																							# update plists and release semaphores
	update_IngestPlist
	update_OutputPlist
																							# setup ingest from remote source
	setup_Destination
	update_DestPlist
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors 

define_Constants

___main___ "${@}"
																							# return value to AppleScript, currently not implemented in AScript
echo "${returnValue}"

exit 0