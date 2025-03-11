package core.io;

import haxe.io.Path;
import sys.FileSystem;
import haxe.Timer;
import EReg;
import core.util.PathUtils;

class FileWatcher2 {
	private var directory:String;
	private var callback:String->Void;
	private var filePattern:String;
	private var regex:EReg;
	private var fileTimestamps:Map<String, Float>;
	private var pollInterval:Int = 1000;
	private var timer:Timer;

	public function new(directory:String, filePattern:String, callback:String->Void) {
		this.directory = directory;
		timer = null;
		this.filePattern = filePattern;
		this.callback = callback;
		this.fileTimestamps = new Map<String, Float>();
		//Log.debug('filePattern:' + filePattern);
		//Log.debug('directory:' + directory);
		this.regex = PathUtils.globToRegex(filePattern);
		scanInitialFiles();
	}


	private function scanInitialFiles() {
		var files = FileSystem.readDirectory(directory);
		for (file in files) {
			// Log.debug('matching file: ${file} with pattern: ${filePattern}...');
			if (matchesPattern(file)) {
				// Log.debug('match!');
				var filePath = Path.join([directory, file]); //directory + "/" + file;
				Log.debug('Adding watch for: ${filePath}');
				fileTimestamps.set(filePath, FileSystem.stat(filePath).mtime.getTime());
			} else {
				// Log.debug('not a match.');
			}
		}
	}

	public function start(pollInterval:Int = 1000) {
		// Log.debug('Starting file watcher...');
		this.pollInterval = pollInterval;
		if (timer != null) {
			timer.stop();
		}
		timer = Timer.delay(checkForChanges, pollInterval); // Check every second
	}

	public function stop() {
		// Log.debug('Stopping file watcher...');
		timer.stop();
		timer = null;
	}

	private function checkForChanges() {
		// Log.debug('Checking for changes in ${directory}...');
		var files = FileSystem.readDirectory(directory);
		for (file in files) {
			if (matchesPattern(file)) {
				// Log.debug('checking file: ${file}...');
				var filePath = Path.join([directory, file]); //directory + "/" + file;
				var fileStat = FileSystem.stat(filePath);
				var lastModified = fileStat.mtime.getTime();

				if (!fileTimestamps.exists(filePath)) {
					// New file detected
					fileTimestamps.set(filePath, lastModified);
					callback(filePath);
				} else if (fileTimestamps.get(filePath) != lastModified) {
					// File modified
					Log.debug('File modified: ${filePath}');
					fileTimestamps.set(filePath, lastModified);
					callback(filePath);
				}
			}
		}
		start(this.pollInterval); // Continue watching
	}

	private function matchesPattern(file:String):Bool {
		return regex.match(file);
	}
}
