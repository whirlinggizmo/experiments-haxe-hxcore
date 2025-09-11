#!/usr/bin/bash

# Run the scripttest app.  We have to use this shell springboard because 
# the hxcpp debugger doesn't allow for args or cwd :(

# get the current directory (this shell script's directory)
currentDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


# Set environment variables
export HXCORE_WORKSPACE_FOLDER="$currentDir/../.."
export HXCORE_PROJECT_ROOT="$currentDir/../.."

# Run the application
$currentDir/out/ScriptTest --sourceDir $currentDir/scripts --scriptDir $currentDir/gen --hotreload
