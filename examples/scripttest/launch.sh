#!/usr/bin/bash

# Run the scripttest app.  We have to use this shell springboard because 
# the hxcpp debugger doesn't allow for args or cwd :(

# get the current directory (this shell script's directory)
currentDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$currentDir/dist/ScriptTest --rootDir $currentDir/dist --sourceDir ../scripts --scriptDir scripts --enableScriptWatcher