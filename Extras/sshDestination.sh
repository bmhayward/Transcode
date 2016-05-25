#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/sshDestinationTraceLog 2>&1

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	sshDestination
#	Copyright (c) 2016 Brent Hayward
#
#
#	This script sets up a Transcode destination for accepting content from a remote ingest
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.0.3, 05-23-2016"
	
	loggerTag="transcode.sshDestinationSetup"
	
	readonly libDir="${HOME}/Library"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")					# get the path to the Transcode folder
	
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"

	readonly sh_echoMsg="${appScriptsPath}/_echoMsg.sh"
	readonly sh_ifError="${appScriptsPath}/_ifError.sh"
}

function sshDestination_Confirm () {
	. "${sh_echoMsg}" ""
	. "${sh_echoMsg}" "========================================================================="
	. "${sh_echoMsg}" "Transcode Setup Destination Auto-Connect"
	. "${sh_echoMsg}" ""
	
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure you want to continue? [Yn]} " response
    case ${response} in
        [Y][E][S]|[Y] )
			# just continue
			. "${sh_echoMsg}" ""
            . "${sh_echoMsg}" "Setting up destination auto-connect to accept content from remote ingest sources..."
			. "${sh_echoMsg}" ""
            ;;

        * )
			# bail out
            exit 1
            ;;
    esac
}

function setup_Destination () {
	local currentUser=${USER}

	echo
	. "${sh_echoMsg}" "Enabling Remote Login"
	
	sudo systemsetup -setremotelogin on

	if [ ! -d "${HOME}/.ssh" ]; then
		mkdir "${HOME}/.ssh"
		chown ${currentUser} "${HOME}/.ssh"
		chmod 0700 "${HOME}/.ssh"
	fi
}

function clean_Up () {
	echo
	echo $'\e[92mThis window can now be closed.\e[0m'
	echo
}

function __main__ () {
	sshDestination_Confirm
	setup_Destination
	
	echo
	. "${sh_echoMsg}" "Destination auto-connect setup completed!"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap '. "${sh_ifError}" ${LINENO} $?' ERR													# trap errors
																								
define_Constants

__main__

exit 0