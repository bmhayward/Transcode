#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/watchFolder_watchFoldersMovedTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	watchFolder_watchFoldersMoved
#	Copyright (c) 2017 Brent Hayward
#		
#	
#	This script watches the Transcode folder. If it is moved to a new location, the folder watch LaunchAgents are updated.
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

function define_Constants () {
	local versStamp="Version 1.1.4, 02-16-2017"
	
	readonly LIBDIR="${HOME}/Library"
	readonly PREFDIR="${LIBDIR}/Preferences"
	readonly APPSCRIPTSPATH="/usr/local/Transcode"
	
	readonly TRANSCODEWATCHPLIST="com.videotranscode.watchfolder.plist"
	readonly INGESTWATCHPLIST="com.videotranscode.ingest.watchfolder.plist"
	readonly COMPLETEDWATCHPLIST="com.videotranscode.completed.watchfolder.plist"
	
	readonly TRANSCODEMOVEDWORKINGPLIST="com.videotranscode.transcode.moved.working.plist"
	readonly TRANSCODEINPROGRESSPLIST="com.videotranscode.transcode.moved.inprogress.plist"
	readonly INGESTINPROGRESSPLIST="com.videotranscode.ingest.moved.inprogress.plist"
	readonly INGESTMOVEDWORKINGPLIST="com.videotranscode.ingest.moved.working.plist"
	readonly COMPLETEDMOVEDWORKINGPLIST="com.videotranscode.completed.moved.working.plist"
	readonly COMPLETEDINPROGRESSPLIST="com.videotranscode.completed.moved.inprogress.plist"
}

	
#-------------------------------------------------------------MAIN-------------------------------------------------------------------
																							# execute
define_Constants

if [[ -e "${LIBDIR}/LaunchAgents/${TRANSCODEWATCHPLIST}" ]]; then
	if [[ -e "${PREFDIR}/${TRANSCODEMOVEDWORKINGPLIST}" ]] && [[ ! -e "${PREFDIR}/${TRANSCODEINPROGRESSPLIST}" ]]; then
																							# the Transcode directory moved, need to update its location
		/bin/bash "${APPSCRIPTSPATH}/batch_transcodeMoved.sh"								# execute batch_transcodeMoved.sh
	fi
fi

if [[ -e "${LIBDIR}/LaunchAgents/${INGESTWATCHPLIST}" ]]; then	
	if [[ -e "${PREFDIR}/${INGESTMOVEDWORKINGPLIST}" ]]  && [[ ! -e "${PREFDIR}/${INGESTINPROGRESSPLIST}" ]]; then
																							# the Ingest directory moved, need to update its location
		/bin/bash "${APPSCRIPTSPATH}/batch_ingestMoved.sh"									# execute batch_ingestMoved.sh
	fi
fi

if [[ -e "${LIBDIR}/LaunchAgents/${COMPLETEDWATCHPLIST}" ]]; then	
	if [[ -e "${PREFDIR}/${COMPLETEDMOVEDWORKINGPLIST}" ]] && [[ ! -e "${PREFDIR}/${COMPLETEDINPROGRESSPLIST}" ]]; then
																							# the Completed directory moved, need to update its location
		/bin/bash "${APPSCRIPTSPATH}/batch_completedMoved.sh"								# execute batch_completedMoved.sh
	fi
fi

exit 0