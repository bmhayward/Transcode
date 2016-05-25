#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/sshSourceTraceLog 2>&1

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	sshSource			
#	Copyright (c) 2016 Brent Hayward
#
#	
#	This script sets up ssh-keys between a Transcode ingest source and destination
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.0, 05-23-2016"
	
	loggerTag="transcode.sshIngestSetup"
		
	readonly libDir="${HOME}/Library"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")						# get the path to the Transcode folder
	
	readonly prefPath="${workDir}/Prefs.txt"
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	
	readonly sh_readPrefs="${appScriptsPath}/_readPrefs.sh"
	readonly sh_writePrefs="${appScriptsPath}/_writePrefs.sh"
	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"	
	
}

function sshIngest_Confirm () {
	. "${sh_echoMsg}" ""
	. "${sh_echoMsg}" "========================================================================="
	. "${sh_echoMsg}" "Transcode Setup Ingest Auto-Connect"
	. "${sh_echoMsg}" ""
	. "${sh_echoMsg}" "Prior to continuing, make sure you have run setupDestinationAutoConnect.command at the Transcode destination."
	
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure you want to continue? [Yn]} " response
    case ${response} in
        [Y][E][S]|[Y] )
			# just continue
			. "${sh_echoMsg}" ""
            . "${sh_echoMsg}" "Setting up ingest auto-connect with the destination..."
			. "${sh_echoMsg}" ""
            ;;

        * )
			# bail out
            exit 1
            ;;
    esac
}

function sshSetup_Keys () {
																						# if necessary, create the .ssh directory
	if [ ! -d "${HOME}/.ssh" ]; then
		mkdir "${HOME}/.ssh"
		chmod 0700 "${HOME}/.ssh"
	fi

	cd "${HOME}/.ssh"
																						# generate the public and private key pair
	ssh-keygen -b 1024 -t rsa -f id_rsa -P ""
}

function sshCopyKeys2_Destination () {
	installedBrews=$(brew list)
	
	if [[ ${installedBrews} != *"ssh-copy-id"* ]]; then
		. "${sh_echoMsg}" ""		
		. "${sh_echoMsg}" "Installing brew ssh-copy-id"
		
		brew install ssh-copy-id
	fi
	
	echo
	read -p 'Destination local administrator shortname: ' sshUserPref
	read -p 'Destination DNS or IP address: ' destAddr
	
	echo
	ssh-copy-id "${sshUserPref}@${destAddr}"
}

function update_Prefs () {
	. "${sh_echoMsg}" "Updating preferences..."
																					# lookup the path to the /Transcode/Remote directory on the destination
	rsyncPathPref=$(ssh ${sshUserPref}@${destAddr} '/usr/local/bin/aliasPath "${HOME}/Library/Application Support/Transcode/Transcode alias"')"/Remote"
		
	if [ -e "${prefPath}" ]; then
		. "${sh_readPrefs}" "${prefPath}"											# read in the preferences from Prefs.txt
		
		rm -f "${prefPath}"															# remove Prefs.txt
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
		readonly ingestPath=""														# get the path to the ingest directory
		readonly outQuality=""														# Output quality setting to use
	fi
	
	. "${sh_writePrefs}" "${prefPath}" "${outExt}" "${deleteWhenDone}" "${movieTag}" "${tvTag}" "${convertedTag}" "${renameFile}" "${movieFormat}" "${tvShowFormat}" "${passedArgs[0]}" "${sshUserPref}" "${rsyncPathPref}" "${ingestPath}" "${extrasTag}" "${outQuality}"
}

function clean_Up () {
	echo
	echo $'\e[92mThis window can now be closed.\e[0m'
	echo
}

function __main__ () {
	sshUserPref=""
	destAddr=""
	rsyncPathPref=""
	
	sshIngest_Confirm
	sshSetup_Keys
	sshCopyKeys2_Destination
	update_Prefs
	
	. "${sh_echoMsg}" "Ingest auto-connect setup completed!"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors
																								
define_Constants

__main__

exit 0
