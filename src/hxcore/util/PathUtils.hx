package hxcore.util;

import haxe.io.Path;

class PathUtils {
    public static function globToRegex(pattern:String):EReg {
		// Convert glob pattern to regular expression
		var regexPattern = StringTools.replace(pattern, ".", "\\."); // Escape dots
		regexPattern = StringTools.replace(regexPattern, "*", ".*"); // Replace '*' with '.*' to match any characters
		regexPattern = StringTools.replace(regexPattern, "?", "."); // Replace '?' with '.' to match any single character
		// Log.debug('regexPattern:' + regexPattern);
		return new EReg("^" + regexPattern + "$", "");
	}

	// credit to https://gist.github.com/haxiomic/98c61a09f6028fd72dccc0053385af76
	public static function relativePath(relativeToAbsolute: String, pathAbsolute: String) {

		if (!Path.isAbsolute(relativeToAbsolute)) {
			// Log.error('relativeToAbsolute is not absolute: ' + relativeToAbsolute);
			return pathAbsolute;
		}

		if (!Path.isAbsolute(pathAbsolute)) {
			// Log.error('pathAbsolute is not absolute: ' + pathAbsolute);
			return pathAbsolute;
		}

		// make both absolute
		pathAbsolute = Path.removeTrailingSlashes(pathAbsolute);
		relativeToAbsolute = Path.removeTrailingSlashes(relativeToAbsolute);
	
		var aPath = pathAbsolute.split('/');
		var aRelativeTo = relativeToAbsolute.split('/');
	
		// find shared part of path
		var matchesUpToIndex = 0;
		for (i in 0...aRelativeTo.length) {
			if (aPath[i] == aRelativeTo[i]) {
				matchesUpToIndex = i;
			} else {
				break;
			}
		}
	
		return [for (_ in 0...(aRelativeTo.length - 1) - matchesUpToIndex) '..']
			.concat(aPath.slice(matchesUpToIndex + 1))
			.join('/');
	}

	public static function getDirectoryTail(path:String):String {
		var normalizedPath = Path.normalize(path); // clean it and fix windows slashes
		var dir = Path.directory(path); // remove filename if any
		var parts = dir.split("/");     // split into path segments
		return parts[parts.length - 1];
	}

	public static function getDirectoryHead(path:String):String {
		var normalizedPath = Path.normalize(path); // clean it and fix windows slashes
		var dir = Path.directory(path); // remove filename if any
		var parts = dir.split("/");     // split into path segments
		return parts[0];
	}
	
	public static function getDirectoryParent(path:String):String {
		var dir = Path.directory(path);         // strips off filename if present
		var normalized = Path.normalize(dir);   // ensures consistent "/"
		var parts = normalized.split("/");
	
		if (parts.length <= 1)
			return ""; // root or already at top level
	
		return parts.slice(0, parts.length - 1).join("/");
	}

	public static function deleteDirectoryRecursively(path:String):Void {
		if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)) {
			var entries = sys.FileSystem.readDirectory(path);
			for (entry in entries) {
				if (sys.FileSystem.isDirectory(path + '/' + entry)) {
					PathUtils.deleteDirectoryRecursively(path + '/' + entry);
					sys.FileSystem.deleteDirectory(path + '/' + entry);
				} else {
					sys.FileSystem.deleteFile(path + '/' + entry);
				}
			}
		}
	}
}
