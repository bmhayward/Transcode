#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/watchFolder_transcodeMovedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_transcodeMoved
#	Copyright (c) 2016-2017 Brent Hayward
#		
#	
#	This script watches the Transcode folder. If it is moved to a new location, the folder watch LaunchAgents are updated.
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.2, 02-06-2017"
	
	readonly libDir="${HOME}/Library"
	readonly prefDir="${libDir}/Preferences"
	readonly appScriptsPath="/usr/local/Transcode"
	
	# readonly prefPath=$(. "_aliasPath.sh" "${libDir}/Application Support/Transcode/Transcode alias")"/Prefs.plist"		# get the path to Prefs.plist
	# readonly ingestPath_=$(. "_readPrefs.sh" "${prefPath}" "IngestDirectoryPath")
	
	readonly batchCMD="${appScriptsPath}/batch_transcodeMoved.sh"									# get the path to batch_transcodeMoved.sh
	readonly movedWorkingPlist="com.videotranscode.transcode.moved.working.plist"
	
	. "_workDir.sh" "${libDir}/LaunchAgents/com.videotranscode.watchfolder.plist"					# sets CONVERTDIR and WORKDIR variables
}

	
#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
define_Constants

if [[ ! -e "${WORKDIR}" ]] && [[ ! -e "${prefDir}/${movedWorkingPlist}" ]]; then
																							# the directory moved, need to update its location
	/bin/bash "${batchCMD}"																	# execute batch_transcodeMoved.sh
fi

# if [ ! -e "${ingestPath_}" ]; then # && [ ! -e "${prefDir}/${movedWorkingPlist}" ]; then
# 																							# the directory moved, need to update its location
# 	# /bin/bash "${batchCMD}"																# execute batch_ingestMoved.sh
# 	
# 	echo "Ingest path changed!"
# fi

exit 0