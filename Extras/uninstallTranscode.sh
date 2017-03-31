#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/uninstallTranscodeTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	uninstallTranscode
#	Copyright (c) 2016-2017 Brent Hayward		
#	
#	
#	This script uninstalls Transcode's infrastructure. It does not remove the Transcode folder, as there may be items 
#	still in the directory that a user needs or wants
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
                                                     										# define version number
	local versStamp="Version 1.2.5, 03-31-2017"
	readonly scriptVers="${versStamp:8:${#versStamp}-20}"
	
	loggerTag="transcode.uninstall"
	
	readonly LIBDIR="${HOME}/Library"
	readonly APPSCRIPTSPATH="${LIBDIR}/Application Scripts/com.videotranscode.transcode"
	
	updateThis="0"																			# all by default
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	# loggerTag is defined as global in the calling script
	
	if [[ $# -eq 1 ]]; then
		echo "${1}"																			# echo to the Terminal
	fi
	
    echo "${1}" 2>&1 | logger -t "${loggerTag}"												# echo to syslog
}

function if_Error () {
	# ${1}: last line of error occurrence
	# ${2}: error code of last command

	local lastLine=""
	local lastErr=""
	local currentScript=""
	
	lastLine="${1}"
	lastErr="${2}"
	currentScript=$(basename -- "${0}")
																							# if lastErr > 0 then echo error msg and log
	if [[ ${lastErr} -gt 0 ]]; then
		echo 2>&1 | logger -t "${loggerTag}"
		echo ""
		echo "${currentScript}: "$'\e[91m'"Something went awry :-("
		echo "${currentScript}: Something went awry :-(" 2>&1 | logger -t "${loggerTag}"
		echo "Script error encountered on $(date): Line: ${lastLine}: Exit status of last command: ${lastErr}"
		echo "Script error encountered on $(date): Line: ${lastLine}: Exit status of last command: ${lastErr}" 2>&1 | logger -t "${loggerTag}"
		echo "Exiting..."
		echo $'\e[0m'
		echo "Exiting..." 2>&1 | logger -t "${loggerTag}"

		exit 1
	fi
}

function uninstall_Confirm () {
	echo_Msg ""
	echo_Msg "========================================================================="
	echo_Msg "Uninstall Transcode"
	
    																						# call with a prompt string or use a default
    read -r -p "${1:-Are you sure [Y]? [Command-period to cancel]} " response
    case ${response} in
        [Y]|[Y][E][S] )
			# just continue
			echo_Msg ""
            echo_Msg "Uninstalling Transcode..."
			echo_Msg ""
		;;
		
		[1] )
			# just continue
			echo ""
			echo "Uninstalling Transcode script support..."
			
			updateThis="1"
		;;
		
		[2] )
			# just continue
			echo ""
			echo "Uninstalling Transcode LaunchAgents..."

			updateThis="2"
		;;
		
		[3] )
			# just continue
			echo ""
			echo "Uninstalling Transcode preferences..."

			updateThis="3"
		;;
		
		[4] )
			# just continue
			echo ""
			echo "Uninstalling Transcode Finder Services..."

			updateThis="4"
		;;
		
		[5] )
			# just continue
			echo ""
			echo "Uninstalling brew casks..."

			updateThis="5"
        ;;

		[6] )
			# just continue
			echo ""
			echo "Uninstalling brew packages..."

			updateThis="6"
		;;
		
		[7] )
			# just continue
			echo ""
			echo "Uninstalling ruby gems..."

			updateThis="7"
		;;
		
		[8] )
			# just continue
			echo ""
			echo "Uninstalling commandline tools..."

			updateThis="8"
        ;;

		[9] )
			# just continue
			echo ""
			echo "Uninstalling brew casks and brew package tools..."

			updateThis="9"
        ;;

		[10] )
			# just continue
			echo ""
			echo "Uninstalling brew casks, brew packages and gem tools..."

			updateThis="10"
        ;;

        * )
																							# bail out
			exit 1
		;;
    esac
}

function uninstall_scriptSupport () {
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "1" ]]; then
		declare -a removeThis_a
																							# remove script support
		removeThis_a[0]="/usr/local/Transcode"
		removeThis_a[1]="${LIBDIR}/Application Support/Transcode"
																							# remove preferences
		for i in "${removeThis_a[@]}"; do
			if [[ -d "${i}" ]]; then
				echo_Msg "Removing ${i}"
				
				rm -rf "${i}"
			elif [[ -e "${i}" ]]; then
				echo_Msg "Removing ${i}"
					
				rm -f "${i}"
			fi
		done
	fi
}

function uninstall_launchAgents () {
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "2" ]]; then
		declare -a removeThis_a
	
		removeThis_a[0]="${LIBDIR}/LaunchAgents/com.videotranscode.brewautoupdate.plist"
		removeThis_a[1]="${LIBDIR}/LaunchAgents/com.videotranscode.completed.watchfolder.plist"
		removeThis_a[2]="${LIBDIR}/LaunchAgents/com.videotranscode.gem.check.plist"
		removeThis_a[3]="${LIBDIR}/LaunchAgents/com.videotranscode.ingest.watchfolder.plist"
		removeThis_a[4]="${LIBDIR}/LaunchAgents/com.videotranscode.rsync.watchfolder.plist"
		removeThis_a[5]="${LIBDIR}/LaunchAgents/com.videotranscode.watchFolder.plist"
		removeThis_a[6]="${LIBDIR}/LaunchAgents/com.videotranscode.watchfolders.moved.plist"
																							# remove LaunchAgents
		for i in "${removeThis_a[@]}"; do
			echo_Msg "Unloading LaunchAgent and removing ${i}"
		
			capturedOutput=$(launchctl unload "${i}")
			if [[ "${capturedOutput}" != *"No such file or directory"* ]]; then
				rm -f "${i}"
			fi
		done
	fi
}

function uninstall_preferenceFiles () {
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "3" ]]; then
		declare -a removeThis_a
	
		removeThis_a[0]="${LIBDIR}/Preferences/com.videotranscode.batch.onhold.plist"
		removeThis_a[1]="${LIBDIR}/Preferences/com.videotranscode.batch.waiting.plist"
		removeThis_a[2]="${LIBDIR}/Preferences/com.videotranscode.batch.working.plist"
		removeThis_a[3]="${LIBDIR}/Preferences/com.videotranscode.completed.moved.working.plist"
		removeThis_a[4]="${LIBDIR}/Preferences/com.videotranscode.gem.update.inprogress.plist"
		removeThis_a[5]="${LIBDIR}/Preferences/com.videotranscode.gem.update.plist"
		removeThis_a[6]="${LIBDIR}/Preferences/com.videotranscode.ingest.batch.onhold.plist"
		removeThis_a[7]="${LIBDIR}/Preferences/com.videotranscode.ingest.batch.waiting.plist"
		removeThis_a[8]="${LIBDIR}/Preferences/com.videotranscode.ingest.batch.working.plist"
		removeThis_a[9]="${LIBDIR}/Preferences/com.videotranscode.ingest.moved.working.plist"
		removeThis_a[10]="${LIBDIR}/Preferences/com.videotranscode.rsync.batch.onhold.plist"	
		removeThis_a[11]="${LIBDIR}/Preferences/com.videotranscode.rsync.batch.waiting.plist"
		removeThis_a[12]="${LIBDIR}/Preferences/com.videotranscode.rsync.batch.working.plist"
		removeThis_a[13]="${LIBDIR}/Preferences/com.videotranscode.transcode.full.update.plist"
		removeThis_a[14]="${LIBDIR}/Preferences/com.videotranscode.transcode.moved.working.plist"
		removeThis_a[15]="${LIBDIR}/Preferences/com.videotranscode.transcode.update.plist"
		removeThis_a[16]="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"		
																							# remove preferences
		for i in "${removeThis_a[@]}"; do
			if [[ -e "${i}" ]]; then
				echo_Msg "Removing ${i}"
	
				rm -f "${i}"
			fi
		done
	fi
}

function uninstall_finderServices () {
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "4" ]]; then
		declare -a removeThis_a
	
		removeThis_a[0]="${LIBDIR}/Services/Transcode • Update Finder Info.workflow"
		removeThis_a[1]="${LIBDIR}/Services/Transcode • Transmogrify Video.workflow"
																							# remove the Finder Services
		for i in "${removeThis_a[@]}"; do
			if [[ -e "${i}" ]]; then
				echo_Msg "Removing Finder Service ${i}"
	
				rm -rf "${i}"
			fi
		done
	fi
}

function uninstall_brewPkgs () {
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "6" ]] || [[ "${updateThis}" == "9" ]] || [[ "${updateThis}" == "10" ]]; then
		declare -a removeThis_a
	
		removeThis_a[0]="atomicparsley"
		removeThis_a[1]="ffmpeg"
		removeThis_a[2]="mkvtoolnix"
		removeThis_a[3]="mp4v2"
		removeThis_a[4]="mplayer"
		removeThis_a[5]="rsync"
		removeThis_a[6]="tag"
		removeThis_a[7]="ssh-copy-id"
		removeThis_a[8]="terminal-notifier"
		removeThis_a[9]="handbrake"
																							# brew, remove if in place
		for i in "${removeThis_a[@]}"; do
			if [[ ${installedBrews} == *"${i}"* ]]; then
				echo_Msg "Removing brew ${i}"
			
				brew uninstall ${i}
			fi
		done
	fi
}

function uninstall_brewCasks (){
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "5" ]] || [[ "${updateThis}" == "9" ]] || [[ "${updateThis}" == "10" ]]; then
		declare -a removeThis_a
	
		removeThis_a[0]="filebot"
		removeThis_a[1]="java"
	
		installedCasks=$(brew cask list)
																							# brew, remove caskroom/cask/brew-cask if in place
		for i in "${removeThis_a[@]}"; do
			if [[ ${installedCasks} == *"${i}"* ]]; then
				echo_Msg "Removing brew-cask ${i}"
			
				brew cask uninstall ${i}
			fi
		done
	fi
}

function uninstall_rubyGems () {
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "7" ]] || [[ "${updateThis}" == "10" ]]; then
		declare -a removeThis_a
	
		removeThis_a[0]="video_transcoding"
																							# ruby, remove gems if in place
		installedGems=$(gem list)
	
		for i in "${removeThis_a[@]}"; do
			if [[ ${installedGems} == *"${i}"* ]]; then
				echo_Msg "Removing gem ${i}"
			
				sudo gem uninstall ${i}
			fi
		done
	
		if [[ ${installedBrews} == *"ruby"* ]]; then
			echo_Msg "Removing brew ruby"
		
			brew rm ruby
		fi
	fi
}

function uninstall_commandLineTools () {
	local removeThis=""
	
	if [[ "${updateThis}" == "0" ]] || [[ "${updateThis}" == "8" ]]; then
		removeThis="/Library/Developer/CommandLineTools"
	
		if [[ -d "${removeThis}" ]]; then
			echo_Msg "Removing ${removeThis}"
		
			sudo rm -rf "${removeThis}"
		fi
	fi
}

function clean_Up () {
	echo
	echo $'\e[92mThis window can now be closed.\e[0m'
	echo
}

function __main__ () {
	uninstall_Confirm
	uninstall_scriptSupport
	uninstall_launchAgents
	uninstall_preferenceFiles
	uninstall_finderServices
	uninstall_brewCasks
	
	installedBrews=$(brew list)
	
	uninstall_brewPkgs
	uninstall_rubyGems
	
	uninstall_commandLineTools
	
	echo_Msg ""
	echo_Msg "Transcode was succesfully uninstalled.\nThe Transcode folder has been left in place."
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap 'if_Error ${LINENO} $?' ERR															# trap errors
printf '\e[8;24;130t'																		# set the Terminal window size to 148x24
echo -n -e "\033]0;Uninstall Transcode\007"													# set the Terminal window title
printf "\033c"																				# clear the Terminal screen


define_Constants

__main__

exit 0