#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/private/tmp/service_UpdateFinderInfoTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	service_UpdateFinderInfo
#	Copyright (c) 2016-2017 Brent Hayward
#
#
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.3.7, 02-16-2017"
	
	loggerTag="transcode.serviceMetadata"
	
	readonly LIBDIR="${HOME}/Library"
																							# get the path to the Transcode folder, sets the workDir variable
	. "_workDir.sh" "${LIBDIR}/LaunchAgents/com.videotranscode.watchfolder.plist"
	
	readonly PREFPATH="${LIBDIR}/Preferences/com.videotranscode.preferences.plist"
}

function get_Prefs () {
	local prefValues=""
	local saveIFS=""
																							# create the default preferences file if it does not exist	
	if [[ ! -e "${PREFPATH}" ]]; then
	   . "_writePrefs.sh" "${PREFPATH}"
	fi
																							# read in the preferences
	prefValues=$(. "_readPrefs.sh" "${PREFPATH}" "OriginalFileTags" "ExtrasTags" "MovieTags" "TVTags")
	
	declare -a keyValue_a
	
	saveIFS=${IFS}
	IFS=':' read -r -a keyValue_a <<< "${prefValues}"
	IFS=${saveIFS}																			# restore IFS
	
	convertedTag="${keyValue_a[0]}"
	extrasTag_="${keyValue_a[1]}"
	movieTag_="${keyValue_a[2]}"
	tvTag_="${keyValue_a[3]}"
}

function set_FinderTag () {
	# ${1}: path to the file
	
	local tag2Apply=""
	local titleName=""
	
	local tag2Apply=${convertedTag}
	local titleName=$(. "_matchVal.sh" "${1}")												# get the string to strip out

	if [[ "${1##*.}" != "mkv" ]]; then
		if [[ "${titleName}" =~ ([Ss][0][0][Ee][0-9]+) ]]; then		
			tag2Apply=${extrasTag_}
		elif [[ "${titleName}" =~ ([Ss][0-9]+[Ee][0-9]+) ]]; then
			tag2Apply=${tvTag_}
		elif [[ "${titleName}" == "Featurettes" ]] || [[ "${titleName}" == "Behind The Scenes" ]] || [[ "${titleName}" == "Deleted Scenes" ]] || [[ "${titleName}" == "Interviews" ]] || [[ "${titleName}" == "Scenes" ]] || [[ "${titleName}" == "Shorts" ]] || [[ "${titleName}" ==  "Trailers" ]]; then
			tag2Apply=${extrasTag_}
		else
			tag2Apply=${movieTag_}
		fi
	fi
																							# set Finder tags
	. "_finderTag.sh" "${tag2Apply}" "${1}" "${extrasTag_}"
	
	. "_echoMsg.sh" "Updated Finder tags for ${1} to ${tag2Apply}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

define_Constants

get_Prefs

for f in "${@}"; do
																							# get the path passed by Automator
	searchPath="${f}"
																							# directory, apply
	if [[ -d "${searchPath}" ]]; then
		. "_echoMsg.sh" ""
																							# directory|directories, apply to each file
		cd "${searchPath}" || exit 1
	
		find . -print0 | while IFS= read -r -d '' file
		do
		   if [[ "${file##*/}" != "." && "${file##*/}" != ".DS_Store" && ! -d "${file}" ]]; then
				fileExt="${file##*.}"
																							# only deal with .m4v, .mp4 or .mkv files
				if [[ "${fileExt}" == "m4v" || "${fileExt}" == "mp4" || "${fileExt}" == "mkv" ]] && [[ "${file}" != *"^"* ]]; then
					. "_metadataTag.sh" "${file}" "title"
					set_FinderTag "${file}"
					
					. "_echoMsg.sh" "Updated Finder info for ${file##*/}"
				fi
			fi
		done
	else
																							# single file, apply
		fileExt="${searchPath##*.}"
																							# only deal with .m4v, .mp4 or .mkv files
		if [[ "${fileExt}" == "m4v" || "${fileExt}" == "mp4" || "${fileExt}" == "mkv" ]] && [[ "${file}" != *"^"* ]]; then
			. "_metadataTag.sh" "${searchPath}" "title"
			set_FinderTag "${searchPath}"
			
			. "_echoMsg.sh" "Updated Finder info for ${searchPath##*/}"
		fi
	fi

	. "_echoMsg.sh" ""
done

exit 0