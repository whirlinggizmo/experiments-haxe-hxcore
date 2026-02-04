package hxcore.io;

import hxcore.util.PathUtils;
import hxcore.logging.Log;
#if sys
import haxe.Timer;
import sys.FileSystem;
#end

enum FileChangeEvent {
	Added;
	Modified;
	Removed;
}

typedef FileChangeCallback = (String, FileChangeEvent) -> Void;
#if sys
var ignoredFiles = [".*/import.hx$"];
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
	var filters:Array<EReg>;
	var pollInterval:Int;
	var callback:FileChangeCallback;
	var files:Map<String, Float>;
	var loopTimer:Timer;
	var running:Bool;

	public function new(rootDirectory:String, callback:FileChangeCallback) {
		this.callback = callback;
		this.pollInterval = 1000;
		this.files = new Map<String, Float>();
		this.loopTimer = null;
		this.running = false;
		this.rootDirectory = null;
		this.filters = [];

		if (rootDirectory == null) {
			Log.error('FileWatcher: Root directory not set');
			return;
		}

		if (callback == null) {
			Log.error('FileWatcher: Callback not set');
			return;
		}

		// if (!FileSystem.exists(rootDirectory) || !FileSystem.isDirectory(rootDirectory)) {
		//	Log.debug('FileWatcher: Invalid root directory: $rootDirectory');
		//	return;
		// }

		/*
			try {
				this.filter = filter != null ? new EReg(filter, "") : null;
			} catch (e) {
				Log.debug('FileWatcher: Invalid filter: $filter');
				this.filter = null;
			}
		 */

		this.rootDirectory = rootDirectory;

		Log.debug('FileWatcher: Root directory: ${this.rootDirectory}');
	}

	public function add(regex:EReg) {
		if (regex == null) {
			Log.error('FileWatcher: Invalid regex watch pattern: $regex');
			return;
		}

		// update the filter to include the new path
		this.filters.push(regex);


		// should we consider added files new/changed?
		scanDirectory(false);

		//Log.debug('FileWatcher: watch pattern: ${this.filters}');
	}

	public function remove(regex:EReg) {
		if (regex == null) {
			Log.error('FileWatcher: Invalid regex watch pattern: $regex');
			return;
		}

		this.filters.remove(regex);
	}

	public function start(pollInterval:Int = 1000) {
		if (rootDirectory == null) {
			Log.error("Filewatcher: Root directory not set, aborting.");
			return;
		}
		this.pollInterval = pollInterval;

		stop();

		scanDirectory(false);
		running = true;
		// loopTimer = Timer.delay(loop, watchInterval);
		loop();
	}

	public function stop() {
		running = false;
		if (loopTimer != null) {
			loopTimer.stop();
			loopTimer = null;
		}
	}

	public function dispose() {
		stop();
		this.files.clear();
	}

	public function tick() {
		scanDirectory();
	}

	private var currentFiles = new Map<String, Float>();

	function scanDirectory(invokeCallbackOnChange:Bool = true) {
		function processDirectory(dir:String) {
			if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) {
				return;
			}

			if (isIgnored(dir, [ignoredDirectoriesRegex])) {
				return;
			}
			for (file in FileSystem.readDirectory(dir)) {
				var fullPath = haxe.io.Path.join([dir, file]);
				if (FileSystem.isDirectory(fullPath)) {
					processDirectory(fullPath);
				} else {
					var relativePath = PathUtils.relativePathSafe(rootDirectory, fullPath);
					// Log.debug('Relative path: ${relativePath}');
					if (!isIgnored(file, [ignoredFilesRegex]) && matchesFilter(relativePath)) {
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
		}

		processDirectory(rootDirectory);

		// Detect removed files
		for (file in files.keys()) {
			if (!currentFiles.exists(file)) {
				callback(file, Removed);
			}
		}

		// Update file map with current state
		files = currentFiles.copy();
		currentFiles.clear();
	}

	function matchesFilter(file:String):Bool {
		if (filters == null) {
			return true; // no filters, so all files match
		}
		for (filter in filters) {
			/*
			if (StringTools.contains(file, "Test")) {
				Log.debug('Checking ${file} against filter ${filter}: ${filter.match(file)}');
			}
			*/
			if (filter.match(file)) {
				return true;
			}
		}

		return false;
	}

	function loop() {
		if (!running)
			return;
		scanDirectory();
		loopTimer = Timer.delay(loop, pollInterval);
	}
}
#else
class FileWatcher {
	public function new(rootDirectory:String, filter:Null<String>, callback:FileChangeCallback) {
		Log.debug("FileWatcher not available on this platform (requires sys)");
	}

	public function add(path:String) {
		Log.debug("FileWatcher not available on this platform (requires sys)");
	}

	public function addRegex(path:String) {
		Log.debug("FileWatcher not available on this platform (requires sys)");
	}

	public function remove(path:String) {
		Log.debug("FileWatcher not available on this platform (requires sys)");
	}

	public function removeRegex(path:String) {
		Log.debug("FileWatcher not available on this platform (requires sys)");
	}

	public function start() {
		Log.debug("FileWatcher not available on this platform (requires sys)");
	}

	public function stop() {
		// Log.debug("FileWatcher not available on this platform (requires sys)");
	}
}
#end
