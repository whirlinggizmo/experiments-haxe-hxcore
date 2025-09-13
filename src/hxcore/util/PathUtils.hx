package hxcore.util;

import haxe.io.Path;
#if sys
import sys.io.Process;
import sys.FileSystem;
#end

class PathUtils {
	/**
	 * Calculates the relative path from one absolute path to another.
	 * 
	 * Given two absolute paths, returns the relative path that would navigate
	 * from the first path to the second path using "../" notation.
	 * 
	 * @param relativeToAbsolute The base path (absolute) to calculate relative path from
	 * @param pathAbsolute The target path (absolute) to calculate relative path to
	 * @return The relative path string, or the original pathAbsolute if either path is not absolute
	 * 
	 * @example
	 * relativePath("/home/user/project", "/home/user/project/src/main.hx") // returns "src/main.hx"
	 * relativePath("/home/user/project/src", "/home/user/project/lib") // returns "../lib"
	 * relativePath("/home/user/project", "/home/user/project") // returns ""
	 * 
	 * @credit https://gist.github.com/haxiomic/98c61a09f6028fd72dccc0053385af76
	 */
	public static function relativePath(relativeToAbsolute:String, pathAbsolute:String) {
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

		var result = [for (_ in 0...(aRelativeTo.length - 1) - matchesUpToIndex) '..'].concat(aPath.slice(matchesUpToIndex + 1)).join('/');

		if (!StringTools.startsWith(result, "./")) {
			result = "./" + result;
		}

		return result;
	}

	public static function ensureDirectory(path:String):String {
		path = normalizePath(path);
		if (FileSystem.exists(path)) {
			if (FileSystem.isDirectory(path)) {
				return path; // = Path.addTrailingSlash(path);
			}
		}
		Log.error('Path is not a directory: $path');
		return Path.directory(path);
	}

	public static function getDirectoryTail(path:String):String {
		// var normalizedPath = normalizePath(path); // clean it and fix windows slashes
		var dir = ensureDirectory(path); // remove filename if any
		var parts = dir.split("/");
		return parts[parts.length - 1];
	}

	public static function getDirectoryHead(path:String):String {
		var dir = ensureDirectory(path); // remove filename if any
		var parts = dir.split("/"); // split into path segments
		return parts[0];
	}

	public static function getDirectoryParent(path:String):String {
		var dir = ensureDirectory(path); // strips off filename if present
		// var normalized = normalizePath(dir); // ensures consistent "/"
		var parts = dir.split("/");

		if (parts.length <= 1)
			return ""; // root or already at top level

		return parts.slice(0, parts.length - 1).join("/");
	}

	public static function deleteDirectoryRecursively(path:String):Void {
		#if sys
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
		#else
		Log.error("sys is unavailable, unable to delete directory recursively");
		#end
	}

	public static function normalizePath(path:String):String {
		return Path.normalize(path);
	}

	public static function makeAbsolutePath(base:String, path:String):String {
		if (path == null || path.length == 0) {
			Log.error('Path is not set: $path');
			return base;
		}
		if (base == null || base.length == 0 || !Path.isAbsolute(base)) {
			Log.error('Base path is not absolute: $base');
			return path;
		}

		if (Path.isAbsolute(path)) {
			Log.warn('Path is already absolute: $path');
			return path;
		}

		return normalizePath(Path.join([base, path]));
	}

	private static function validateFilePath(path:String):Bool {
		if (path == null || path.length == 0) {
			return false;
		}
		return FileSystem.exists(path) && !FileSystem.isDirectory(path);
	}

	private static function validateDirectoryPath(path:String):Bool {
		if (path == null || path.length == 0) {
			return false;
		}
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
	}

	public static function findHaxeExecutablePath():Null<String> {
		#if sys
		final cmd = 'haxe';
		var lookupCmd = switch (Sys.systemName()) {
			case "Windows": "where";
			default: "which"; // linux/osx?
		};

		function isValidHaxePath(haxeExePath:String):Bool {
			try {
				// try to run haxe with '--version' to verify it works
				// Note: we use process instead of command so the results don't get displayed
				final process = new Process(haxeExePath, ['--version']);
				final exitCode = process.exitCode();
				process.close();
				return exitCode == 0;
			} catch (e) {
				return false;
			}
		}

		function isSandboxedEnvironment():Bool {
			// Check for Snap environment
			if (Sys.getEnv("SNAP") != null || Sys.getEnv("SNAP_NAME") != null) {
				return true;
			}
			// Check for Flatpak environment
			if (Sys.getEnv("FLATPAK_ID") != null || Sys.getEnv("FLATPAK_SANDBOX") != null) {
				return true;
			}
			// Check for AppImage environment
			if (Sys.getEnv("APPIMAGE") != null) {
				return true;
			}
			// Check for Docker environment
			if (Sys.getEnv("container") != null) {
				return true;
			}
			return false;
		}

		var isSandboxed = isSandboxedEnvironment();

		// check for environment variable HAXEPATH first
		var path = Sys.getEnv("HAXEPATH");
		if (path != null) {
			// Log.info("Found environment variable HAXEPATH: " + path);
			var haxePath = Path.join([path, cmd]);
			if (isValidHaxePath(haxePath)) {
				return haxePath;
			}
			Log.warn('Unable to find "$cmd" in HAXEPATH: "$path", falling back to "$lookupCmd"...');
			Log.warn('HAXEPATH: ' + path);
			Log.warn('Attempted bin path: ' + haxePath);
		}

		// Check for user-specific environment variables (works in both sandboxed and non-sandboxed)
		var userHaxePath = Sys.getEnv("HAXE_USER_PATH");
		if (userHaxePath != null) {
			Log.info("Found HAXE_USER_PATH: " + userHaxePath);
			if (isValidHaxePath(userHaxePath)) {
				return userHaxePath;
			}
		}

		// Check for sandbox-specific environment variables
		if (isSandboxed) {
			Log.info("Detected sandboxed environment, checking sandbox-specific paths...");

			// Check Snap-specific paths
			var snapPath = Sys.getEnv("SNAP");
			if (snapPath != null) {
				var snapHaxePaths = [
					Path.join([snapPath, "usr", "bin", cmd]),
					Path.join([snapPath, "bin", cmd]),
					Path.join([snapPath, "usr", "local", "bin", cmd])
				];
				for (snapHaxePath in snapHaxePaths) {
					Log.info("Checking Snap path: " + snapHaxePath);
					if (isValidHaxePath(snapHaxePath)) {
						return snapHaxePath;
					}
				}
			}

			// Check Flatpak-specific paths
			var flatpakPath = Sys.getEnv("FLATPAK_SANDBOX");
			if (flatpakPath != null) {
				var flatpakHaxePaths = [
					Path.join(["/usr", "bin", cmd]),
					Path.join(["/app", "bin", cmd]),
					Path.join(["/usr", "local", "bin", cmd])
				];
				for (flatpakHaxePath in flatpakHaxePaths) {
					Log.info("Checking Flatpak path: " + flatpakHaxePath);
					if (isValidHaxePath(flatpakHaxePath)) {
						return flatpakHaxePath;
					}
				}
			}

			// Check for sandbox-specific environment variables
			var sandboxHaxePath = Sys.getEnv("HAXE_SANDBOX_PATH");
			if (sandboxHaxePath != null) {
				Log.info("Found HAXE_SANDBOX_PATH: " + sandboxHaxePath);
				if (isValidHaxePath(sandboxHaxePath)) {
					return sandboxHaxePath;
				}
			}
		}

		// try using which/where lookup (depending on the platform)
		try {
			var proc = new Process(lookupCmd, [cmd]);
			var output = proc.stdout.readAll().toString().split("\n")[0];
			output = StringTools.trim(output);
			proc.close();
			if (output != null && isValidHaxePath(output)) {
				return output;
			} else {
				Log.warn('Unable to find $cmd using $lookupCmd');
				// return null;
			}
		} catch (e) {
			Log.warn('Error while trying to find $cmd using $lookupCmd: ' + e.message);
			return null;
		}

		try {
			// try to find haxe in common install locations
			var possiblePaths = [
				// Windows
				"C:/HaxeToolkit/haxe",
				"C:/Program Files/HaxeToolkit/haxe",
				"C:/Program Files (x86)/HaxeToolkit/haxe",
				// macOS
				"/usr/local/bin/haxe",
				"/opt/homebrew/bin/haxe", // M1 macs with homebrew
				"/usr/bin/haxe",
				// Linux
				"/usr/bin/haxe",
				"/usr/local/bin/haxe",

				// Common user-specific locations
				Path.join([Sys.getEnv("HOME") ?? "", "bin", cmd]),
				Path.join([Sys.getEnv("HOME") ?? "", ".local", "bin", cmd]),
				Path.join([Sys.getEnv("HOME") ?? "", "haxe", "haxe"]),
				Path.join([Sys.getEnv("HOME") ?? "", "toolchains", "haxe", "haxe"]),
				Path.join([Sys.getEnv("HOME") ?? "", "opt", "haxe", "haxe"]),

				// my machine
				Path.join([Sys.getEnv("USER_TOOLCHAINS") ?? "", "haxe", "current", "haxe"]),
			];

			for (possiblePath in possiblePaths) {
				Log.info("Checking common path for haxe: " + possiblePath);
				if (isValidHaxePath(possiblePath)) {
					return possiblePath;
				}
			}
		} catch (e) {
			Log.warn('Error while checking common haxe paths: ' + e.message);
			if (isSandboxed) {
				Log.warn('You are running in a sandboxed environment. This may prevent access to system-installed Haxe.');
				Log.warn('Consider the following solutions:');
				Log.warn('1. Set HAXE_SANDBOX_PATH environment variable to point to your Haxe installation');
				Log.warn('2. Set HAXE_USER_PATH environment variable to the full path of your Haxe executable');
				Log.warn('3. Install Haxe within the sandbox if possible');
				Log.warn('4. Use classic confinement for Snap packages (snap install --classic)');
				Log.warn('5. Bundle Haxe with your application');
			} else {
				Log.warn('Are you in a sandboxed environment (like Snap or Flatpak)?');
			}
			return null;
		}

		// last resort, just try 'haxe' and hope it's in the PATH
		Log.info("Falling back to default command: " + cmd);
		if (isValidHaxePath(cmd)) {
			return cmd;
		}

		// unable to find haxe
		if (isSandboxed) {
			Log.error("Unable to find haxe executable in sandboxed environment.");
			Log.error("Solutions for sandboxed environments:");
			Log.error("1. Set HAXE_SANDBOX_PATH environment variable to the full path of your Haxe executable");
			Log.error("2. Set HAXE_USER_PATH environment variable to the full path of your Haxe executable");
			Log.error("3. Set HAXEPATH environment variable to the Haxe installation directory");
			Log.error("4. Use classic confinement for Snap (linux) packages: snap install --classic your-package");
		} else {
			Log.error("Unable to find haxe executable. Please ensure haxe is installed and available in your system PATH, or set the HAXEPATH environment variable to the haxe installation directory.");
		}
		#else
		Log.error("sys is unavailable, unable to find haxe executable");
		#end
		return null;
	}

	/* example ignored files and directories:
		var ignoredFiles = ["import.hx"];
		var ignoredDirectories = ["unused", "externs"];
	 */
	static public function getFilesRecursive(directory:String, ignoredFiles:Array<String> = null, ignoredDirectories:Array<String> = null):Array<String> {
		var files:Array<String> = [];

		var ignoredFilesRegex = ignoredFiles != null && ignoredFiles.length > 0 ? new EReg(ignoredFiles.join("|"), "i") : null;
		var ignoredDirectoriesRegex = ignoredDirectories != null
			&& ignoredDirectories.length > 0 ? new EReg(ignoredDirectories.join("|"), "i") : null;

		// helper function to check if a file or directory is ignored
		function isIgnored(file:String, ignoreRegexes:Array<EReg>):Bool {
			for (regex in ignoreRegexes) {
				if (regex.match(file)) {
					return true;
				}
			}
			return false;
		}

		if (sys.FileSystem.exists(directory)) {
			if (isIgnored(directory, [ignoredDirectoriesRegex])) {
				return files;
			}
			for (file in sys.FileSystem.readDirectory(directory)) {
				var path = haxe.io.Path.join([directory, file]);
				if (!sys.FileSystem.isDirectory(path)) {
					if (!isIgnored(file, [ignoredFilesRegex])) {
						files.push(path);
					}
				} else {
					var subdirectory = haxe.io.Path.addTrailingSlash(path);
					files = files.concat(getFilesRecursive(subdirectory)); // Add files from subdirectory
				}
			}
		} else {
			trace('"$directory" does not exist');
		}

		return files;
	}
}
