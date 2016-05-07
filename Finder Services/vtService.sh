#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/private/tmp/transcodeServiceTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	vtService
#	Copyright (c) 2016 Brent Hayward
#		
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.7, 04-22-2016"
	
	readonly libDir="${HOME}/Library"
	readonly workDir=$(aliasPath "${libDir}/Application Support/Transcode/Transcode alias")					# get the path to the Transcode folder
	
	readonly prefPath="${workDir}/Prefs.txt"
	readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"
	
	readonly sh_readPrefs="${appScriptsPath}/_readPrefs.sh"
	readonly sh_writePrefs="${appScriptsPath}/_writePrefs.sh"
}

function get_Prefs () {
																				# create the default preferences file if it does not exist	
	if [ ! -e "${prefPath}" ]; then
	   . "${sh_writePrefs}" "${prefPath}"
	fi
	
	. "${sh_readPrefs}" "${prefPath}"											# read in the preferences from Prefs.txt
}

function extract_MatchVal () {
	# ${1}: filename w/wo file extension
	# Returns: matched value
	
	local fileTitle="${1}"
	local matchVal=""
																	# TV Show
	if [[ "${fileTitle}" =~ ([[:space:]]-[[:space:]]*([Ss][0-9]+[Ee][0-9]+)*-[e][0-9]+) ]]; then
		matchVal=${BASH_REMATCH[1]}				 				# get the matched text from the string SXXEYYEZZ
	elif [[ "${fileTitle}" =~ ([[:space:]]-[[:space:]]*([Ss][0-9]+[Ee][0-9]+)) ]]; then
		matchVal=${BASH_REMATCH[1]}								# get the matched text from the string SXXEYY
	elif [[ "${fileTitle}" =~ ([[:space:]]*[(][0-9]+[)]) ]]; then
		matchVal=${BASH_REMATCH[1]}		 						# get the matched text from the string (YEAR)
	elif [[ "${fileTitle}" =~ (Featurettes) ]] || [[ "${fileTitle}" =~ (Behind The Scenes) ]] || [[ "${fileTitle}" =~ (Deleted Scenes) ]] || [[ "${fileTitle}" =~ (Interviews) ]] || [[ "${fileTitle}" =~ (Scenes) ]] || [[ "${fileTitle}" =~ (Shorts) ]] || [[ "${fileTitle}" =~  (Trailers) ]]; then
		matchVal=${BASH_REMATCH[1]}		 						# get the matched text from the string extras
	fi
	
	echo "${matchVal}"
}

function set_MetadataTag () {
	# ${1}: file path

	local metaVal="${1##*/}"
	local matchVal=$(extract_MatchVal "${metaVal}")													# get the string to strip out

	metaVal=${metaVal%${matchVal}*}																	# remove the matched value from the metaVal

	atomicparsley "${1}" --overWrite --title "${metaVal}"  2>&1 | logger -t transcode.service		# set the metadata tag
}

function set_FinderTag () {
	# ${1}: path to the file
	
	echo 2>&1 | logger -t transcode.service
	echo " Updating Finder tags..." 2>&1 | logger -t transcode.service
	
	local applyTag=""
	local titleName=$(extract_MatchVal "${1}")											# get the string to strip out

	if [[ "${titleName}" =~ ([Ss][0][0][Ee][0-9]+) ]]; then		
		applyTag=${extrasTag}
	elif [[ "${titleName}" =~ ([Ss][0-9]+[Ee][0-9]+) ]]; then
		applyTag=${tvTag}
	elif [[ "${titleName}" == "Featurettes" ]] || [[ "${titleName}" == "Behind The Scenes" ]] || [[ "${titleName}" == "Deleted Scenes" ]] || [[ "${titleName}" == "Interviews" ]] || [[ "${titleName}" == "Scenes" ]] || [[ "${titleName}" == "Shorts" ]] || [[ "${titleName}" ==  "Trailers" ]]; then
		applyTag=${extrasTag}
	elif [[ "${1##*.}" == "mkv" ]]; then
		applyTag=${convertedTag}
	else
		applyTag=${movieTag}
	fi
	
	tag --add "${applyTag}"	 "${1}"	 2>&1 | logger -t transcode.service					# set Finder tags	
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

define_Constants
get_Prefs

for f in "${@}"; do
	searchPath="${f}" 									# get the path passed by Automator

	if [ -d "${searchPath}" ]; then
														# directory|directories, apply to each file
		cd "${searchPath}"
	
		find . -print0 | while IFS= read -r -d '' file
		do
		   if [[ "${file##*/}" != "." && "${file##*/}" != ".DS_Store" && ! -d "${file}" ]]; then
				fileExt="${file##*.}"
														# only deal with .m4v, .mp4 or .mkv files
				if [[ "${fileExt}" = "m4v" || "${fileExt}" = "mp4" || "${fileExt}" = "mkv" ]]; then
					echo "" 2>&1 | logger -t transcode.service
					echo "${file##*/}" 2>&1 | logger -t transcode.service
					set_MetadataTag "${file}"
					set_FinderTag "${file}"
				fi
			fi
		done
	else
														# single file, apply
		fileExt="${searchPath##*.}"
														# only deal with .m4v, .mp4 or .mkv files
		if [[ "${fileExt}" = "m4v" || "${fileExt}" = "mp4" || "${fileExt}" = "mkv" ]]; then
			echo "" 2>&1 | logger -t transcode.service
			echo "${searchPath##*/}" 2>&1 | logger -t transcode.service
			set_MetadataTag "${searchPath}"
			set_FinderTag "${searchPath}"
		fi
	fi

	echo "" 2>&1 | logger -t transcode.service
done

exit 0