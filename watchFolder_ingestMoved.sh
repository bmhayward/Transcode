#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/watchFolder_ingestMovedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_ingestMoved
#	Copyright (c) 2016-2017 Brent Hayward
#		
#	
#	This script watches the Ingest folder. If it is moved to a new location, the folder watch launchAgents are updated.
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.3, 01-18-2017"
	local prefPath=""
	
	readonly libDir="${HOME}/Library"
	readonly prefDir="${libDir}/Preferences"
	readonly appScriptsPath="/usr/local/Transcode"
	readonly batchCMD="${appScriptsPath}/batch_ingestMoved.sh"															# get the path to batch_ingestMoved.sh
	readonly prefPath=$(. "_aliasPath.sh" "${libDir}/Application Support/Transcode/Transcode alias")"/Prefs.plist"		# get the path to Prefs.plist
	readonly ingestPath_=$(. "_readPrefs.sh" "${prefPath}" "IngestDirectoryPath")										# read in the preferences from Prefs.txt
	readonly movedWorkingPlist="com.videotranscode.ingest.moved.working.plist"
}
	
#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
define_Constants

if [[ ! -e "${ingestPath_}" ]] && [[ ! -e "${prefDir}/${movedWorkingPlist}" ]]; then
																							# the directory moved, need to update its location
	/bin/bash "${batchCMD}"																	# execute batch_ingestMoved.sh
fi

exit 0