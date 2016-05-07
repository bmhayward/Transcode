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
	local versStamp="Version 1.0.2, 05-07-2016"
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"											# echo to the Terminal
	fi
    echo "${1}" 2>&1 | logger -t sshDestination.setup		# echo to syslog
}

function if_Error () {
	# ${1}: last line of error occurence
	# ${2}: error code of last command
	
	local lastLine="${1}"
	local lastErr="${2}"
																		# if lastErr > 0 then echo error msg and log
	if [[ ${lastErr} -eq 0 ]]; then
		echo_Msg ""
		echo_Msg "Something went awry :-("
		echo_Msg "Script error encountered $(date) in ${scriptName}.sh: line ${lastLine}: exit status of last command: ${lastErr}"
		echo_Msg "Exiting..."
		
		exit 1
	fi
}

function sshDestination_Confirm () {
	echo_Msg ""
	echo_Msg "========================================================================="
	echo_Msg "Transcode Setup Destination Auto-Connect"
	echo_Msg ""
	
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure you want to continue? [Yn]} " response
    case ${response} in
        [Y][E][S]|[Y] )
			# just continue
			echo_Msg ""
            echo_Msg "Setting up destination auto-connect to accept content from remote ingest sources..."
			echo_Msg ""
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
	echo_Msg "Enabling Remote Login"
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
	echo_Msg "Destination auto-connect setup completed!"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																								# execute
trap clean_Up INT TERM EXIT																		# always run clean_Up regardless of how the script terminates
trap "exit" INT																					# trap user cancelling
trap 'if_Error ${LINENO} $?' ERR																# trap errors
																								
define_Constants

__main__

exit 0