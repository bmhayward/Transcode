#!/usr/bin/env bash

# set -xv; exec 1>>/private/tmp/_writePrefsTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	_writePrefs		
#	Copyright (c) 2016 Brent Hayward		
#	
#	
#	This script is a library function for the Transcode suite
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function write_Prefs () {
	declare -a passedArgs

	passedArgs=("${@}")
		
	local outExtPref="mkv"														# get the transcode file extension
	local deleteWhenDonePref="false"											# what to do with the original files when done
	local movieTagPref="purple,Movie,VT"										# Finder tags for movie files
	local tvTagPref="orange,TV Show,VT"											# Finder tags for TV show files
	local convertedTagPref="blue,Converted"										# Finder tags for original files that have been transcoded		
	local renameFilePref="auto"													# whether or not to auto-rename files
	local movieFormatPref=""													# movie rename format
	local tvShowFormatPref="{n} - {'"'"'s'"'"'+s.pad(2)}e{e.pad(2)} - {t}"		# TV show rename format
	local plexPathPref=""														# where to put the transcoded files in Plex
	local sshUserPref=""														# get the ssh username
	local rsyncPathPref=""														# get the path to the rsync Remote directory
	local ingestPathPref=""														# get the path to the ingest directory
	local extrasTagPref="yellow,Extra,VT"										# Finder tags for Extra show files
	local outQualityPref=""														# Output quality setting to use
	local tlaHelper="Numbers.app"												# Transcode Log Analyzer helper app
	
	if [ ${#passedArgs[@]} -gt 1 ]; then
								# new values were passed
		outExtPref="${passedArgs[1]}"											# get the transcode file extension
		deleteWhenDonePref="${passedArgs[2]}"									# what to do with the original files when done
		movieTagPref="${passedArgs[3]}"											# Finder tags for movie files
		tvTagPref="${passedArgs[4]}"											# Finder tags for TV show files
		convertedTagv="${passedArgs[5]}"										# Finder tags for original files that have been transcoded		
		renameFilePref="${passedArgs[6]}"										# whether or not to auto-rename files
		movieFormatPref="${passedArgs[7]}"										# movie rename format
		tvShowFormatPref="${passedArgs[8]}"										# TV show rename format
		plexPathPref="${passedArgs[9]}"											# where to put the transcoded files in Plex
		sshUserPref="${passedArgs[10]}"											# get the ssh username
		rsyncPathPref="${passedArgs[11]}"										# get the path to the rsync Remote directory
		ingestPathPref="${passedArgs[12]}"										# get the path to the ingest directory
		extrasTagPref="${passedArgs[13]}"										# Finder tags for Extra show files
		outQualityPref="${passedArgs[14]}"										# Output quality setting to use
		tlaHelper="${passedArgs[15]}"											# Transcode Log Analyzer helper app
	fi
	
	printf "${outExtPref}\n${deleteWhenDonePref}\n${movieTagPref}\n${tvTagPref}\n${convertedTagPref}\n${renameFilePref}\n${movieFormatPref}\n${tvShowFormatPref}\n${plexPathPref}\n${sshUserPref}\n${rsyncPathPref}\n${ingestPathPref}\n${extrasTagPref}\n${outQualityPref}\n${tlaHelper}" >> "${passedArgs[0]}"
}

function __main__ () {
	write_Prefs "${@}"
}

#-------------------------------------------------------------MAIN-------------------------------------------------------------------

# Version 1.0.2, 05-10-2016

__main__ "${@}"