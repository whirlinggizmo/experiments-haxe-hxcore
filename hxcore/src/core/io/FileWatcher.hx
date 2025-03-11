package core.io;

#if sys
import haxe.Timer;
import sys.FileSystem;
#end

typedef FileChangeCallback = (String, FileEvent) -> Void;

enum FileEvent {
	Added;
	Modified;
	Removed;
}

#if sys

var ignoredFiles = ["import.hx"];
var ignoredDirectories = ["unused"];
var ignoredFilesRegex = new EReg(ignoredFiles.join("|"), "i");
var ignoredDirectoriesRegex = new EReg(ignoredDirectories.join("|"), "i");

function isIgnored(file:String, ignoreRegexes:Array<EReg>):Bool {
	for (regex in ignoreRegexes) {
		if (regex.match(file)) {
			return true;
		}
	}
	return false;
}

class FileWatcher {
	var rootDirectory:String;
	var filter:Null<EReg>;
	var pollInterval:Int;
	var callback:FileChangeCallback;
	var files:Map<String, Float>;
    var loopTimer:Timer;
    var running:Bool;

	public function new(rootDirectory:String, filter:Null<String>, callback:FileChangeCallback) {
		if (!FileSystem.exists(rootDirectory) || !FileSystem.isDirectory(rootDirectory)) {
			Log.error('FileWatcher: Invalid root directory: $rootDirectory');
			rootDirectory = null;
			return;
		}

		this.rootDirectory = rootDirectory;
		try {
			this.filter = filter != null ? new EReg(filter, "") : null;
		} catch (e) {
			Log.error('FileWatcher: Invalid filter: $filter');
			this.filter = null;
		}
		//this.filter = filter != null ? new EReg(filter, "") : null;
		this.callback = callback;
		this.pollInterval = 1000;
		this.files = new Map<String, Float>();
        this.loopTimer = null;
        this.running = false;
	}

	public function start(pollInterval:Int = 1000) {
		if (rootDirectory == null) {
			Log.warn("Filewatcher: Root directory not set, ignoring.");
		}
        this.pollInterval = pollInterval;

        stop();

		scanDirectory(false);
        running = true;
        //loopTimer = Timer.delay(loop, watchInterval);
        loop();
	}

    public function stop() {
        running = false;
        if (loopTimer != null) {
            loopTimer.stop();
            loopTimer = null;
        }
    }

	function scanDirectory(invokeCallbackOnChange:Bool = true) {
		var currentFiles = new Map<String, Float>();

		function processDirectory(dir:String) {
			if (isIgnored(dir, [ignoredDirectoriesRegex])) {
				return;
			}
			for (file in FileSystem.readDirectory(dir)) {
				var fullPath = haxe.io.Path.join([dir, file]);
				if (FileSystem.isDirectory(fullPath)) {
					processDirectory(fullPath);
				} else if (matchesFilter(file) && !isIgnored(file, [ignoredFilesRegex])) {
					var modifiedTime = FileSystem.stat(fullPath).mtime.getTime();
					currentFiles.set(fullPath, modifiedTime);

					if (invokeCallbackOnChange) {
						// Detect added or modified files
						if (!files.exists(fullPath)) {
							callback(fullPath, Added);
						} else if (files.get(fullPath) != modifiedTime) {
							callback(fullPath, Modified);
						}
                    } else {
                        Log.debug("Watching file: " + fullPath);
                    }
				}
			}
		}

		processDirectory(rootDirectory);

		// Detect removed files
		for (file in files.keys()) {
			if (!currentFiles.exists(file)) {
				callback(file, Removed);
			}
		}

		// Update file map with current state
		files = currentFiles;
	}

	function matchesFilter(file:String):Bool {
		return filter == null || filter.match(file);
	}

	function loop() {
        if (!running) return;
		scanDirectory();
		loopTimer = Timer.delay(loop, pollInterval);
	}
}

#else

class FileWatcher {
    public function new(rootDirectory:String, filter:Null<String>, callback:FileChangeCallback, watchInterval:Int = 1000) {
        //Log.warn("FileWatcher not available on this platform (requires sys)");
    }

    public function start() {
        Log.warn("FileWatcher not available on this platform (requires sys)");
    }

    public function stop() {
        //Log.warn("FileWatcher not available on this platform (requires sys)");
    }
}
#end