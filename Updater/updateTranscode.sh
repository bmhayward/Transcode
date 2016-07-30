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
	local versStamp="Version 1.3.0, 07-30-2016"
	
	loggerTag="transcode.update"
	
	local DIR=""
	local SOURCE="${BASH_SOURCE[0]}"
	
	while [ -h "${SOURCE}" ]; do 												# resolve ${SOURCE} until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
		SOURCE="$(readlink "${SOURCE}")"
		[[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" 						# if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	
	readonly comLabel="com.videotranscode.transcode"
	
	readonly libDir="${HOME}/Library"
	readonly appScriptsPath="${libDir}/Application Scripts/${comLabel}"
	readonly prefDir="${libDir}/Preferences"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")
	
	readonly updaterPath=$(mktemp -d "/tmp/transcodeUpdater_XXXXXXXXXXXX")
	
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
	readonly sh_updatePost="${appScriptsPath}/Transcode Updater.app/Contents/Resources/updateTranscodePost.sh"
	readonly plistBuddy="/usr/libexec/PlistBuddy"
	readonly versCurrent=$(${plistBuddy} -c 'print :CFBundleShortVersionString' "${appScriptsPath}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
	
	fullUpdate="false"
	needsUpdate="false"
	SHA1Clean="false"
}

function check4Update_Transcode () {
	local downloadedZipFile="Transcode Updater.zip"
	local capturedOutput=""
	
	. "${sh_echoMsg}" "Checking for Transcode updates..." ""
																				# get a copy of Transcode Updater.app
	curl -L -o "${updaterPath}/${downloadedZipFile}" github.com/bmhayward/Transcode/raw/master/Updater/Transcode%20Updater.zip > /dev/null		
																				# extract the Version.plist from the archive
	unzip -j "${updaterPath}/${downloadedZipFile}" "Transcode Updater.app/Contents/Resources/transcodeVersion.plist" -d "${updaterPath}" > /dev/null
																				# remove any remnants of the unzip
	rm -rf "${updaterPath}/__MACOSX"
																				# check the version numbers for an update
	capturedOutput=$(diff --brief "${appScriptsPath}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist" "${updaterPath}/transcodeVersion.plist")

	if [[ "${capturedOutput}" = *"differ"* ]]; then
																				# needs update
		needsUpdate="true"
	fi
}

function update_Transcode () {
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
	if [[ "${needsUpdate}" == "true" ]] && [[ ! -e "${waitingPlist}" || ! -e "${onHoldPlist}" || ! -e "${workingPlist}" ]]; then
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
		if [ "${auSHA1}" == "${SHA1}" ]; then
			SHA1Clean="true"
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
																				# needs full update
				fullUpdate="true"
			fi

			. "${sh_echoMsg}" "Updating Transcode from ${versCurrent} to ${versUpdate}." ""
			. "${sh_sendNotification}" "Transcode Update" "Updated from ${versCurrent} to ${versUpdate}"
		
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
						if [[ "${fileName}" != "updateTranscode.sh" && "${fileName}" != "updateTranscodeGems.sh" ]]; then
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
																				# remove the full update flag
			fullUpdate="false"
			
			. "${sh_echoMsg}" "SHA1 checksums do not match, update skipped." ""
		fi
	elif [[ -e "${waitingPlist}" || -e "${onHoldPlist}" || -e "${workingPlist}" ]]; then
		. "${sh_echoMsg}" "Update deferred." ""
	else
		. "${sh_echoMsg}" "Already up-to-date." ""
	fi	
}

function clean_Up () {
	local plistDir="${libDir}/LaunchAgents"
	local plistName="com.videotranscode.gem.check"
	local plistFile="${plistDir}/${plistName}.plist"
																				# delete the auto-update files from /tmp
	rm -rf "${updaterPath}"
																				# make sure everything can execute
	find "${appScriptsPath}/" -name "*.sh" -exec chmod +x {} \;
	find "${workDir}/" -name "*.command" -exec chmod +x {} \;
	find "${workDir}/Extras/" -name "*.command" -exec chmod +x {} \;
}

function __main__ () {
	define_Constants

	check4Update_Transcode
	update_Transcode
	. "${sh_updatePost}"														# executing this way to run an updated version if available
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates																							
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors

__main__

exit 0