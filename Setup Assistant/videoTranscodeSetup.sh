#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/tmp/transcodeSetupTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	transcodeSetup
#	Copyright (c) 2016 Brent Hayward
#		
#	
#	This script installs everything required to transcode video using the batch.sh script
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.9, 05-07-2016"
	
	readonly plistBuddy="/usr/libexec/PlistBuddy"
	readonly plistDir="${HOME}/Library/LaunchAgents"
	readonly scriptsDir="${HOME}/Library/Application Scripts"
	readonly supportDir="${HOME}/Library/Application Support"
	readonly scriptsDirName="com.videotranscode.transcode"
}

function echo_Msg () {
	# ${1}: message to echo
	# ${2}: flag to suppress echo
	
	if [ $# -eq 1 ]; then
		echo "${1}"											# echo to the Terminal
	fi
    echo "${1}" 2>&1 | logger -t transcode.install			# echo to syslog
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

function install_Tools () {
	# Ruby - exit if not installed
	if ! command -v ruby > /dev/null; then
		echo_Msg "Ruby 2.0 or later is required to complete installation.\nPlease install the latest version of OS X."
		exit 1
	fi
	
	# move the /Transcode alias to ~/Library/Application Support/Transcode
	if [ -e "${supportDir}/Transcode alias" ]; then
		echo_Msg "Moving Transcode alias to ${supportDir}/Transcode"
		
		mv -f "${supportDir}/Transcode alias" "${supportDir}/Transcode/Transcode alias"
	fi
		
	# XCode command-line tools - install if not in place
	if [[ ! -d "/Library/Developer/CommandLineTools" && ! -d "/Applications/Xcode.app/Contents/Developer" ]]; then
		xcode-select --install
	else
		echo_Msg "Xcode Tools already installed"
	fi
	
	# /local/bin - create if not in place, brew should have done this already
	if [ ! -d "/usr/local/bin" ]; then
		echo_Msg "Creating /usr/local/bin"
		
		mkdir -p "/usr/local/bin"
	fi
	
	# aliasPath - copy to /local/bin
	if [ -e "${supportDir}/aliasPath" ]; then
		echo_Msg "Moving aliasPath to /usr/local/bin"
		
		ditto "${supportDir}/aliasPath" "/usr/local/bin"
		rm -f "${supportDir}/aliasPath"
	fi
}

function create_Plists () {
																													# create the launchAgent directory if it does not exist
	if [ ! -d "${plistDir}" ]; then
	  mkdir -p "${plistDir}"
	fi
	
	declare -a plistName
	plistName[0]="com.videotranscode.brewautoupdate"
	plistName[1]="com.videotranscode.watchfolder"
	plistName[2]="com.videotranscode.rsync.watchfolder"
		
	plistFile="${plistDir}/${plistName[0]}.plist"

	if [ ! -e "${plistFile}" ]; then 																				# write out the auto-update LaunchAgent plist to ~/Library/LaunchAgent
		${plistBuddy} -c 'Add :Label string "'"${plistName[0]}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		${plistBuddy} -c 'Add :ProgramArguments array' "${plistFile}"
		${plistBuddy} -c 'Add :ProgramArguments:0 string "'"${scriptsDir}/${scriptsDirName}/brewAutoUpdate.sh"'"' "${plistFile}"
		${plistBuddy} -c 'Add :RunAtLoad bool false' "${plistFile}"
		${plistBuddy} -c 'Add :StartCalendarInterval array' "${plistFile}"
		${plistBuddy} -c 'Add :StartCalendarInterval:0 dict' "${plistFile}"
		${plistBuddy} -c 'Add :StartCalendarInterval:0:Hour integer 3' "${plistFile}"
		${plistBuddy} -c 'Add :StartCalendarInterval:0:Minute integer 0' "${plistFile}"

		chmod 644 "${plistFile}"
		
		launchctl load "${plistFile}"																				# load the launchAgent
	fi

	plistFile="${plistDir}/${plistName[1]}.plist"																	# get the watch folder launch agent

	if [ ! -e "${plistFile}" ]; then																				# write out the watch folder LaunchAgent plist to ~/Library/LaunchAgent
		local watchPath=$(aliasPath "${supportDir}/Transcode/Transcode alias")"/Convert"							# get the path to /Transcode/Convert from the alias left behind by Video Transcode Setup Assistant

		${plistBuddy} -c 'Add :Label string "'"${plistName[1]}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		${plistBuddy} -c 'Add :ProgramArguments array' "${plistFile}"
		${plistBuddy} -c 'Add :ProgramArguments:0 string "'"${scriptsDir}/${scriptsDirName}/watchFolder.sh"'"' "${plistFile}"
		${plistBuddy} -c 'Add :RunAtLoad bool true' "${plistFile}"
		${plistBuddy} -c 'Add :WatchPaths array' "${plistFile}"
		${plistBuddy} -c 'Add :WatchPaths:0 string "'"${watchPath}"'"' "${plistFile}"

		chmod 644 "${plistFile}"
		
		launchctl load "${plistFile}"																				# load the launchAgent
	fi
	
	plistFile="${plistDir}/${plistName[2]}.plist"																	# get the watch folder launch agent

	if [ ! -e "${plistFile}" ]; then																				# write out the watch folder LaunchAgent plist to ~/Library/LaunchAgent
		local watchPath=$(aliasPath "${supportDir}/Transcode/Transcode alias")"/Remote"								# get the path to /Transcode/Remote from the alias left behind by Video Transcode Setup Assistant

		${plistBuddy} -c 'Add :Label string "'"${plistName[2]}"'"' "${plistFile}"; cat "${plistFile}" > /dev/null 2>&1
		${plistBuddy} -c 'Add :ProgramArguments array' "${plistFile}"
		${plistBuddy} -c 'Add :ProgramArguments:0 string "'"${scriptsDir}/${scriptsDirName}/watchFolder_rsync.sh"'"' "${plistFile}"
		${plistBuddy} -c 'Add :RunAtLoad bool true' "${plistFile}"
		${plistBuddy} -c 'Add :WatchPaths array' "${plistFile}"
		${plistBuddy} -c 'Add :WatchPaths:0 string "'"${watchPath}"'"' "${plistFile}"

		chmod 644 "${plistFile}"
		
		launchctl load "${plistFile}"																				# load the launchAgent
	fi
}

function install_brewPkgs () {
	# Homebrew - install if not in place
	if ! command -v brew > /dev/null; then
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	
	declare -a installThis
	
	installThis[0]="atomicparsley"
	installThis[1]="ffmpeg"
	installThis[2]="mkvtoolnix"
	installThis[3]="mp4v2"
	installThis[4]="mplayer"
	installThis[5]="rsync"
	installThis[6]="tag"
	installThis[7]="ruby"
	
	installedBrews=$(brew list)
	
	# brew, install packages
	for i in "${installThis[@]}"; do
		if [[ ${installedBrews} != *"${i}"* ]]; then			
			echo_Msg "Installing brew ${i}"
			
			if [[ "${i}" != *"rsync"* ]]; then
				brew install ${i}
			else
				brew tap homebrew/dupes
				brew install rsync
			fi
		fi
	done
}

function install_brewCasks () {
	declare -a installThis
	
	installThis[0]="java"
	installThis[1]="handbrakecli"
	installThis[2]="filebot"
	
	installedCasks=$(brew cask list)
	
	# brew, install caskroom/cask/brew-cask
	for i in "${installThis[@]}"; do
		if [[ ${installedCasks} != *"${i}"* || "${i}" = *"java"* ]]; then
			echo_Msg "Installing brew-cask ${i}"
			
			brew cask install ${i}
		fi
	done
}

function install_rubyGems () {
	declare -a installThis
	
	installThis[0]="video_transcoding"
	installThis[1]="terminal-notifier"
	
	# ruby, remove gems if in place
	installedGems=$(gem list)
	
	for i in "${installThis[@]}"; do
		if [[ ${installedGems} != *"${i}"* ]]; then
			echo_Msg "Installing gem ${i}"
			
			sudo gem install ${i}
		fi
	done
}

function setup_Complete () {
	local scriptDir="$(cd "$(dirname "$0")" && pwd)"
	local icnsPath="${scriptDir}/AutomatorApplet.icns"
	
	echo_Msg "Transcode install complete" ""
	
cat << EOF | osascript -l AppleScript > /dev/null
set iconPath to "$icnsPath" as string
set posixPath to POSIX path of iconPath
set hfsPath to POSIX file posixPath

display dialog "Setup Complete!" buttons {"OK"} default button "OK" with title "Transcode Setup Assistant" with icon file hfsPath
EOF

	Safari "http://www.videolan.org/index.html"
	Safari "http://www.makemkv.com/download/"
}

function Safari () {
	# Will open a New Safari window with argument 1.
osascript << EOD
tell application "Safari" to make new document with properties {URL:"$1"}
return
EOD
}

function clean_Up () {
	echo
	echo $'\e[92mThis window can now be closed.\e[0m'
	echo
}

function __main__ () {
	install_Tools
	create_Plists
	install_brewPkgs
	install_brewCasks
	install_rubyGems
	setup_Complete
}


#----------------------------------------------------------MAIN----------------------------------------------------------------
																							# Execute
trap clean_Up INT TERM EXIT																	# always run clean_Up regardless of how the script terminates
trap "exit" INT																				# trap user cancelling
trap 'if_Error ${LINENO} $?' ERR															# trap errors
printf '\e[8;24;130t'																		# set the Terminal window size to 148x24

define_Constants

__main__

exit 0