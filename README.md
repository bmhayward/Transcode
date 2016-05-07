# Transcode
Tools to batch transcode and process videos

## About
Transcode is a set of tools to batch transcode Blu-ray Discs and DVDs into a smaller, more portable format while remaining high enough quality to be mistaken for the originals. Transcode is a wrapper that builds upon Don Melton’s exceptional video transcoding toolset.

## Requirements
OS X 10.11 or later.
Most of the tools in this package require other software to function properly. Transcode Setup Assistant will install these command line programs:

* `aliasPath`
* `atomicparsely`
* `ffmpeg`
* `filebot`
* `handbrakecli`
* `Homebrew`
* `Java`
* `mkvtoolnix`
* `mplayer`
* `rsync`
* `ruby`
* `tag`
* `terminal-notifier`
* `transcode_video`
* `Xcode command-line tools`

In addition, a Blu-ray or DVD [reader](www.amazon.com/Samsung-External-Blu-ray-SE-506CB-RSBD/dp/B00JJGFRIQ/ref=pd_sim_147_4?ie=UTF8&dpID=21l0PtOb6GL&dpSrc=sims&preST=_AC_UL160_SR160,160_&refRID=02K1BF563A1RE2C79GV5) is recommended.

## Installation
Launch Transcode Setup Assistant:
```
Select the location for the Transcode folder
```

One installer and the Terminal will launch:
```
1. Complete the installation of the Xcode command-line tools
2. Select the open Terminal window once Xcode has been installed
3. Press [Return]
4. Enter the local administrator password when prompted
5. Click OK once the Setup Assistant has completed
6. Close the open Terminal window
7. Safari has opened the download page for two additional tools you may find helpful, MakeMKV and VLC
```

## Usage
Drop `.mkv` files into:
```
/Transcode/Convert
```
to automatically batch convert video files. Transcoding will start after all content has been copied to the Convert folder.

### Batch Transcoding

Transcode uses a batch queue mechanism to manage content for transcoding. As content is added to the Convert folder, a ```watchFolder``` LaunchAgent waits for the Convert folder size to stabilize.
Once the Convert folder has stabilized, ```watchFolder``` launches ```batch.command``` from the Transcode folder to begin transcoding.
Depending upon how content is being added to the Convert folder, `watchFolder` will wait:
```
a minimum of 20 seconds after folder stabilization to start transcoding
a maximum of 60 seconds after folder stabilization to start transcoding
```
If content is added while transcoding is active, `watchFolder` will create a new batch queue for the added content. The new batch queue will start once the active queue has completed.
This queueing process allows for content to be continuously streamed or copied to the Convert folder.

To stop the transcode process:
```
1. Select the transcode process Terminal window
2. Press command-period
```
To restart a transcode process:
```
Double-click batch.command in the Transcode folder
or
Drag files out of and back into the Convert folder
```
### Compression

The transcode-video tool configures the x264 video encoder within HandBrake to provide a constrained variable bitrate (CVBR) mode. This automatically targets bitrates appropriate for different input resolutions.
