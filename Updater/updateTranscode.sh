#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/tmp/updateTranscodeTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscode		
#	Copyright (c) 2016 Brent Hayward		
#
#
#	This script checks to see if Transcode or Ruby Gems need to be udpated and logs the results to the system log
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.2.0, 06-24-2016"
	
	loggerTag="transcode.update"
	
	readonly prefDir="${libDir}/Preferences"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")
	
	readonly updaterPath=$(mktemp -d "/tmp/transcodeUpdater_XXXXXXXXXXXX")
	readonly icnsPath="${libDir}/Application Support/Transcode/Transcode_custom.icns"
	
	readonly comLabel="com.videotranscode.transcode"
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	readonly plistBuddy="/usr/libexec/PlistBuddy"
	readonly versCurrent=$(${plistBuddy} -c 'print :CFBundleShortVersionString' "${appScriptsPath}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
	
	# From brewAutoUpdate:
		# readonly libDir="${HOME}/Library"
		# readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
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

function clean_Up () {
																				# delete the auto-update files
	rm -rf "${updaterPath}"
																				# run the post-update script and disown from this shell so this script can be updated if needed
	runAndDisown "${appScriptsPath}/Transcode Updater.app/Contents/Resources/updateTranscodePost.sh"
}

function check4Update_Transcode () {
	local needsUpdatePlist="${comLabel}.update.plist"
	local downloadedZipFile="Transcode Updater.zip"
	local capturedOutput=""
	local needsUpdatePath="${prefDir}/${needsUpdatePlist}"
	
	. "${sh_echoMsg}" "Checking for Transcode updates..." ""
																				# has the update been checked for previously
	if [ ! -e "${needsUpdatePath}" ]; then
																				# get a copy of Transcode Updater.app
		curl -L -o "${updaterPath}/${downloadedZipFile}" github.com/bmhayward/Transcode/raw/master/Updater/Transcode%20Updater.zip > /dev/null		
																				# extract the Version.plist from the archive
		unzip -j "${updaterPath}/${downloadedZipFile}" "Transcode Updater.app/Contents/Resources/transcodeVersion.plist" -d "${updaterPath}" > /dev/null
																				# remove any remnants of the unzip
		rm -rf "${updaterPath}/__MACOSX"
																				# check the version numbers for an update
		capturedOutput=$(diff --brief "${appScriptsPath}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist" "${updaterPath}/transcodeVersion.plist")
	
		if [[ "${capturedOutput}" = *"differ"* ]]; then
																				# create the Transcode update sempahore
			touch "${needsUpdatePath}"
		fi
	fi
}

function update_Transcode () {
	local needsUpdatePlist="${comLabel}.update.plist"
	local needsUpdatePath="${prefDir}/${needsUpdatePlist}"
	local needsFullUpdatePlist="${comLabel}.full.update.plist"
	local waitingPlist="{prefDir}/com.videotranscode.batch.waiting.plist"
	local onHoldPlist="{prefDir}/com.videotranscode.batch.onhold.plist"
	local workingPlist="{prefDir}/com.videotranscode.batch.working.plist"
	local downloadedZipFile="AutoUpdater.zip"
	local transcode2Replace=""
	local fileType=""
	local fileName=""
	local versPrevious=""
	local versUpdate=""
	local auSHA1="SHA1_AU.plist"
	local SHA1=""
	local capturedOutput=""
																				# can update happen
	if [[ -e "${needsUpdatePath}" ]] && [[ ! -e "${waitingPlist}" || ! -e "${onHoldPlist}" || ! -e "${workingPlist}" ]]; then
																				# pull down a copy of AutoUpdater
		curl -L -o "${updaterPath}/${downloadedZipFile}" github.com/bmhayward/Transcode/raw/master/Updater/${downloadedZipFile} >/dev/null
																				# pull down a copy of SHA1 checksum
		curl -L -o "${updaterPath}/${auSHA1}" github.com/bmhayward/Transcode/raw/master/Updater/SHA1_AU.plist >/dev/null
																				# read the downloaded SHA1 checksum 
		auSHA1=$(${plistBuddy} -c 'print :SHA1checksum' "${updaterPath}/${auSHA1}")
																				# get the SHA1 checksum from the downloaded .zip file
		capturedOutput=$(shasum "${updaterPath}/${downloadedZipFile}")
		SHA1="${capturedOutput%% *}"
																				# do the SHA1 checksums match?
		if [ "${auSHA1}" == "${SHA1}"  ]; then
																				# extract the auto-update to the AutoUpdater directory in the temp folder
			unzip "${updaterPath}/${downloadedZipFile}" -d "${updaterPath}/${downloadedZipFile%.*}" >/dev/null
																				# unzip any applications in the AutoUpdater directory
			unzip "${updaterPath}/${downloadedZipFile%.*}/*.zip" -d "${updaterPath}/${downloadedZipFile%.*}" >/dev/null
																				# delete any embedded zip files
			rm -f "${updaterPath}/${downloadedZipFile%.*}"/*.zip
																				# remove any remnants of the unzip
			rm -rf "${updaterPath}/__MACOSX"
			rm -rf "${updaterPath}/${downloadedZipFile%.*}/__MACOSX"
																				# get the known previous version from AutoUpdate
			versPrevious=$(${plistBuddy} -c 'print :CFBundleShortVersionString' "${updaterPath}/${downloadedZipFile%.*}/transcodeVersion_Previous.plist")
																				# get the update version number
			versUpdate=$(${plistBuddy} -c 'print :CFBundleShortVersionString' "${updaterPath}/transcodeVersion.plist")
																				# check to see if a full update needs to be done
			if [ "${versCurrent}" != "${versPrevious}"  ]; then
																				# create the Transcode full update semaphore
				touch "${prefDir}/${needsFullUpdatePlist}"
			fi

			. "${sh_echoMsg}" "Updating Transcode from ${versCurrent} to ${versUpdate}." ""
		
			declare -a updateFiles
			updateFiles=( "${updaterPath}/${downloadedZipFile%.*}"/* )			# get a list of filenames with path to convert
		
			for i in "${updateFiles[@]}"; do
																				# get the file extension and file name
				fileType="${i##*.}"
				fileName="${i##*/}"
		
				case "${fileType}" in
					sh|app|command )
																				# is this file in ~/Library/Application Scripts/com.videotranscode.transcode
						transcode2Replace=$(find "${libDir}/Application Scripts/com.videotranscode.transcode" -name "${fileName}")
					
						if [ -z "${transcode2Replace}" ]; then
																				# is this file in /Transcode
							transcode2Replace=$(find "${workDir}" -name "${fileName}")
						fi
					;;
				
					workflow )
																				# file is in ~/Library/Services
						transcode2Replace="${libDir}/Services"	
					;;				
				esac
			
				case "${fileType}" in
					sh|app|command )
				
						if [ "${fileName}" != "updateTranscode.sh" ]; then
																				# move to the update location
							ditto "${i}" "${transcode2Replace}"
						
							. "${sh_echoMsg}" "==> Updated ${fileName}" ""
																				# this script needs to be updated later, move to /tmp for the moment
						elif [ "${fileName}" = "updateTranscode.sh" ]; then
							ditto "${i}" "/tmp"
						
							. "${sh_echoMsg}" "==> Moved ${fileName} to /tmp" ""
						fi
				
					;;
				
					workflow )
				
						cp -R -p "${i}" "${transcode2Replace}"
					
						. "${sh_echoMsg}" "==> Updated ${fileName}" ""
					;;	
				esac
			done
	
			. "${sh_echoMsg}" "Update complete." ""
		else
			if [ -e "${prefDir}/${needsFullUpdatePlist}" ]; then
																				# remove the full update semaphore file
				rm -f "${prefDir}/${needsFullUpdatePlist}"
			fi
			
			. "${sh_echoMsg}" "SHA1 checksums do not match, update skipped." ""
		fi
																				# delete the sempahore file
			rm -f "${needsUpdatePath}"	
	elif [[ -e "${waitingPlist}" || -e "${onHoldPlist}" || -e "${workingPlist}" ]]; then
		. "${sh_echoMsg}" "Update deferred." ""
	else
		. "${sh_echoMsg}" "Already up-to-date." ""
	fi	
}

function __main__ () {
	define_Constants

	check4Update_Transcode
	update_Transcode
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates																							
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0