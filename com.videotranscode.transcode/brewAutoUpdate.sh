#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin export PATH

# set -xv; exec 1>>/tmp/brewAutoUpdateTraceLog 2>&1

#-----------------------------------------------------------------------------------------------------------------------------------																		
#	brewAutoUpdate			
#	Copyright (c) 2016 Brent Hayward		
#
#	
#	This script checks to see if homebrew and installed taps need to be udpated and logs the results to the system log
#	Recommended to use this with launchd
#


#-------------------------------------------------------------MAIN------------------------------------------------------------------

# Version 1.0.5, 05-20-2016

readonly libDir="${HOME}/Library"
readonly appScriptsPath="${libDir}/Application Scripts/com.videotranscode.transcode"

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

# upgrade gems
. "${appScriptsPath}/updateTranscode.sh"

exit 0