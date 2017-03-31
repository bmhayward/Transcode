#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/updateTranscodeTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	updateTranscode		
#	Copyright (c) 2016-2017 Brent Hayward		
#
#
#	This script checks to see if Transcode or Ruby Gems need to be udpated and logs the results to the system log
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.4.2, 03-24-2017"
	
	loggerTag="transcode.update"
	
	local DIR=""
	local SOURCE="${BASH_SOURCE[0]}"
	
	while [[ -h "${SOURCE}" ]]; do 															# resolve ${SOURCE} until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
		SOURCE="$(readlink "${SOURCE}")"
		[[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" 									# if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	
	readonly LIBDIR="${HOME}/Library"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	readonly LIBSCRIPTSPATH="${APPSCRIPTSPATH}/Library"
	
	readonly PREFDIR="${LIBDIR}/Preferences"
	readonly WORKDIR=$(. "_aliasPath.sh" "${LIBDIR}/Application Support/Transcode/Transcode alias")
	
	readonly UPDATERPATH=$(mktemp -d "/tmp/transcodeUpdater_XXXXXXXXXXXX")

	readonly SH_UPDATEPOST="${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/updateTranscodePost.sh"
	readonly PLISTBUDDY="/usr/libexec/PlistBuddy"
	readonly VERSCURRENT=$(${PLISTBUDDY} -c 'print :CFBundleShortVersionString' "${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist")
	
	fullUpdate="false"
	needsUpdate="false"
	SHA256Clean="false"
}

function check4Update_Transcode () {
	local downloadedZipFile=""
	local capturedOutput=""
	
	downloadedZipFile="Transcode Updater.zip"
	
	. "_echoMsg.sh" "Checking for Transcode updates..." ""
																							# get a copy of Transcode Updater.app
	curl -L -o "${UPDATERPATH}/${downloadedZipFile}" github.com/bmhayward/Transcode/raw/master/Updater/Transcode%20Updater.zip > /dev/null		
																							# extract the Version.plist from the archive
	unzip -j "${UPDATERPATH}/${downloadedZipFile}" "Transcode Updater.app/Contents/Resources/transcodeVersion.plist" -d "${UPDATERPATH}" > /dev/null
																							# remove any remnants of the unzip
	rm -rf "${UPDATERPATH}/__MACOSX"
																							# check the version numbers for an update
	capturedOutput=$(diff --brief "${APPSCRIPTSPATH}/Transcode Updater.app/Contents/Resources/transcodeVersion.plist" "${UPDATERPATH}/transcodeVersion.plist")

	if [[ "${capturedOutput}" == *"differ"* ]]; then
																							# needs update
		needsUpdate="true"
	fi
}

function update_Transcode () {
	local waitingPlist=""
	local onHoldPlist=""
	local workingPlist=""
	local downloadedZipFile=""
	local transcode2Replace=""
	local fileType=""
	local fileName=""
	local versPrevious=""
	local versUpdate=""
	local auSHA256=""
	local SHA256=""
	local capturedOutput=""
	
	waitingPlist="{PREFDIR}/com.videotranscode.batch.waiting.plist"
	onHoldPlist="{PREFDIR}/com.videotranscode.batch.onhold.plist"
	workingPlist="{PREFDIR}/com.videotranscode.batch.working.plist"
	downloadedZipFile="AutoUpdater.zip"
	auSHA256="SHA256_AU.plist"
																							# can update happen
	if [[ "${needsUpdate}" == "true" ]] && [[ ! -e "${waitingPlist}" || ! -e "${onHoldPlist}" || ! -e "${workingPlist}" ]]; then
																							# pull down a copy of AutoUpdater
		curl -L -o "${UPDATERPATH}/${downloadedZipFile}" github.com/bmhayward/Transcode/raw/master/Updater/${downloadedZipFile} >/dev/null
																							# pull down a copy of SHA256 checksum
		curl -L -o "${UPDATERPATH}/${auSHA256}" github.com/bmhayward/Transcode/raw/master/Updater/SHA256_AU.plist >/dev/null
																							# read the downloaded SHA256 checksum 
		auSHA256=$(${PLISTBUDDY} -c 'print :SHA256checksum' "${UPDATERPATH}/${auSHA256}")
																							# get the SHA256 checksum from the downloaded .zip file
		capturedOutput=$(shasum -a 256 "${UPDATERPATH}/${downloadedZipFile}")
		SHA256="${capturedOutput%% *}"
																							# do the SHA256 checksums match?
		if [[ "${auSHA256}" == "${SHA256}" ]]; then
			SHA256Clean="true"
																							# extract the auto-update to the AutoUpdater directory in the temp folder
			unzip "${UPDATERPATH}/${downloadedZipFile}" -d "${UPDATERPATH}/${downloadedZipFile%.*}" >/dev/null
																							# unzip any applications in the AutoUpdater directory
			unzip "${UPDATERPATH}/${downloadedZipFile%.*}/*.zip" -d "${UPDATERPATH}/${downloadedZipFile%.*}" >/dev/null
																							# delete any embedded zip files
			rm -f "${UPDATERPATH}/${downloadedZipFile%.*}"/*.zip
																							# remove any remnants of the unzip
			rm -rf "${UPDATERPATH}/__MACOSX"
			rm -rf "${UPDATERPATH}/${downloadedZipFile%.*}/__MACOSX"
																							# get the known previous version from AutoUpdate
			versPrevious=$(${PLISTBUDDY} -c 'print :CFBundleShortVersionString' "${UPDATERPATH}/${downloadedZipFile%.*}/transcodeVersion_Previous.plist")
																							# get the update version number
			versUpdate=$(${PLISTBUDDY} -c 'print :CFBundleShortVersionString' "${UPDATERPATH}/transcodeVersion.plist")
																							# check to see if a full update needs to be done
			if [[ "${VERSCURRENT}" != "${versPrevious}"  ]]; then
																							# needs full update
				fullUpdate="true"
			fi

			. "_echoMsg.sh" "Updating Transcode from ${VERSCURRENT} to ${versUpdate}." ""
		
			declare -a updateFiles_a
			updateFiles_a=( "${UPDATERPATH}/${downloadedZipFile%.*}"/* )					# get a list of filenames with path to convert
		
			for i in "${updateFiles_a[@]}"; do
																							# get the file extension and file name
				fileType="${i##*.}"
				fileName="${i##*/}"
		
				case "${fileType}" in
					sh|app|command )
																							# is this file in /usr/local/Transcode
						transcode2Replace=$(find "${APPSCRIPTSPATH}" -name "${fileName}")
					
							if [[ -z "${transcode2Replace}" ]]; then
								if [[ "${transcode2Replace}" != *"_"* ]]; then
																							# is this file in /Transcode
								transcode2Replace=$(find "${APPSCRIPTSPATH}" -name "${fileName}")
							else
																							# is this file in /Transcode/Library
								transcode2Replace=$(find "${LIBSCRIPTSPATH}" -name "${fileName}")
							fi
						fi
					;;
				
					workflow )
																							# file is in ~/Library/Services
						transcode2Replace="${LIBDIR}/Services"	
					;;				
				esac
			
				case "${fileType}" in
					sh|app|command )
						if [[ "${fileName}" != "updateTranscode.sh" && "${fileName}" != "updateTranscodeGems.sh" ]]; then
																							# move to the update location
							ditto "${i}" "${transcode2Replace}"
						
							. "_echoMsg.sh" "==> Updated ${fileName}" ""
																							# this script needs to be updated later, move to /tmp for the moment
						elif [[ "${fileName}" == "updateTranscode.sh" ]]; then
							ditto "${i}" "/tmp"
						
							. "_echoMsg.sh" "==> Moved ${fileName} to /tmp" ""
						fi
				
					;;
				
					workflow )
						cp -R -p "${i}" "${transcode2Replace}"
					
						. "_echoMsg.sh" "==> Updated ${fileName}" ""
					;;	
				esac
			done
			
			. "_echoMsg.sh" "Update complete." ""
			. "_sendNotification.sh" "Transcode Update" "Updated from ${VERSCURRENT} to ${versUpdate}"
		else
																							# remove the full update flag
			fullUpdate="false"
			
			. "_echoMsg.sh" "SHA256 checksums do not match, update skipped." ""
		fi
	elif [[ -e "${waitingPlist}" || -e "${onHoldPlist}" || -e "${workingPlist}" ]]; then
		. "_echoMsg.sh" "Update deferred." ""
	else
		. "_echoMsg.sh" "Already up-to-date." ""
	fi	
}

function clean_Up () {
																				# delete the auto-update files from /tmp
	rm -rf "${UPDATERPATH}"
																				# make sure everything can execute
	find "${APPSCRIPTSPATH}/" -name "*.sh" -exec chmod +x {} \;
	find "${APPSCRIPTSPATH}/" -name "*.command" -exec chmod +x {} \;
}

function __main__ () {
	define_Constants

	check4Update_Transcode
	update_Transcode
	. "${SH_UPDATEPOST}"														# executing this way to run an updated version if available
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates																							
trap '. "_ifError.sh" ${LINENO} $?' ERR														# trap errors

__main__

exit 0