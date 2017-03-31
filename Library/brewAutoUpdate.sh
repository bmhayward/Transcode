#!/usr/bin/env bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/Transcode:/usr/local/Transcode/Library export PATH		# export PATH to Transcode libraries

# set -xv; exec 1>>/tmp/brewAutoUpdateTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	brewAutoUpdate			
#	Copyright (c) 2016-2017 Brent Hayward		
#
#	
#	This script checks to see if homebrew and installed taps need to be udpated and logs the results to the system log
#	Recommended to use this with launchd
#


#-------------------------------------------------------------MAIN------------------------------------------------------------------

# Version 1.1.3, 03-18-2017

readonly APPSCRIPTSPATH="/usr/local/Transcode"
																							# update brew
brew update 2>&1 | logger -t brew.update
																							# upgrade everything that is installed
brew upgrade 2>&1 | logger -t brew.upgrade
																							# keep brew clean
brew cleanup 2>&1 | logger -t brew.cleanup
																							# update brew-casks
brew cask update 2>&1 | logger -t brew.caskUpdate
																							# keep brew-casks clean
brew cask cleanup 2>&1 | logger -t brew.caskCleanup
																							# copy to /tmp and run from there
ditto "${APPSCRIPTSPATH}/Transcode Updater.app" "/tmp/Transcode Updater.app"
																							# upgrade Transcode and gems
open -a "/tmp/Transcode Updater.app"

exit 0