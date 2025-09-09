package hxcore.scripting;

import haxe.Log;
import sys.FileSystem;
import haxe.io.Path;
import hxcore.logging.Log;
import hxcore.util.PathUtils;
import sys.io.File;
import sys.io.Process;

// A script generator that generates "script" files from .hx files
// hxml can't do variables, so we use this
// Usage example: Compile 'Test.hx' in the 'scripts' directory to 'Test.cppia' in the 'dist/scripts' directory:
// haxe --run hxcore.scripting.ScriptCompiler --scriptDir scripts --scriptName scripts.Test --target cppia --outputDir dist/scripts
@:keep
class ScriptCompiler {
	public static function findHaxeExecutable():Null<String> {
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
				//return null;
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

				// my machine
				"/home/rknopf/toolchains/haxe/haxe-4.3.7/haxe"
			];

			for (possiblePath in possiblePaths) {
				Log.info("Checking common path for haxe: " + possiblePath);
				if (isValidHaxePath(possiblePath)) {
					return possiblePath;
				}
			}
		} catch (e) {
			Log.warn('Error while checking common haxe paths: ' + e.message);
			return null;
		}

		// last resort, just try 'haxe' and hope it's in the PATH
		Log.info("Falling back to default command: " + cmd);
		if (isValidHaxePath(cmd)) {
			return cmd;		
		}

		// unable to find haxe
		Log.error("Unable to find haxe executable. Please ensure haxe is installed and available in your system PATH, or set the HAXEPATH environment variable to the haxe installation directory.");
		return null;
	}

	private static function ensureAbsolute(base:String, path:String):String {
		return Path.isAbsolute(path) ? Path.normalize(path) : Path.normalize(Path.join([base, path]));
	}

	public static function compileScriptInternal(rootDir:String, sourceDir:String, outputDir:String, classesInfoPath:String, target:String, haxeArgs:Array<String>,
			className:String):Int {
		if (sourceDir == null) {
			Log.error("Please specify a source directory.");
			return -1;
		}
		if (outputDir == null) {
			Log.error("Please specify an output directory.");
			return -1;
		}

		rootDir = rootDir ?? Sys.getCwd();
		rootDir = ensureAbsolute(Sys.getCwd(), rootDir);
		sourceDir = ensureAbsolute(rootDir, sourceDir);
		outputDir = ensureAbsolute(rootDir, outputDir);
		classesInfoPath = ensureAbsolute(rootDir, classesInfoPath);

		rootDir = Path.addTrailingSlash(rootDir);
		sourceDir = Path.addTrailingSlash(sourceDir);
		outputDir = Path.addTrailingSlash(outputDir);

		if (StringTools.startsWith(target, "."))
			target = target.substring(1);

		var classNameAsPath = StringTools.replace(className, ".", "/");
		var classPath = new Path(classNameAsPath);
		var packagePath = classPath.dir ?? "";
		var outputFileName = '${classPath.file}.$target';
		var outputFileDir = Path.join([outputDir, packagePath]);
		var outputFilePath = Path.join([outputFileDir, outputFileName]);
		var hxFilePath = Path.join([sourceDir, classNameAsPath + ".hx"]);

		var outputFileDir = Path.join([outputDir, packagePath]);
		var outputFilePath = Path.join([outputFileDir, outputFileName]);

		Log.debug('Compiling class: $className');
		Log.debug('Root dir: $rootDir');
		Log.debug('Source file: $hxFilePath');
		Log.debug('Output file: $outputFilePath');
		Log.debug('ClassesInfo file: $classesInfoPath');

		if (FileSystem.exists(outputFilePath))
			FileSystem.deleteFile(outputFilePath);

		if (!FileSystem.exists(outputFileDir))
			Log.debug('Creating output directory: $outputFileDir');
			FileSystem.createDirectory(outputFileDir);
		
		if (!FileSystem.exists(hxFilePath)) {
			Log.error('Class file not found: $hxFilePath');
			return -1;
		}


		//var classInfoFile = Path.join([sourceDir, "export_classes.info"]);
		if (!FileSystem.exists(classesInfoPath)) {
			Log.error('Class info file not found: $classesInfoPath');
			return -1;
		}

		var args = ["-cp", sourceDir, "-lib", "hxcore", "-D", 'dll_import=$classesInfoPath'];
		#if emscripten
		args.push("-D");
		args.push("CPPIA_NO_JIT");
		#end
		args = args.concat(trimArgs(haxeArgs));
		args = args.concat(['-$target', outputFilePath, className]);

		var cmd = findHaxeExecutable();
		if (cmd == null) {
			Log.error('Unable to find haxe executable');
			return -1;
		}

		Log.debug('Command: $cmd');
		Log.debug('Args: $args');

		Log.debug('Full command: $cmd ' + args.join(" "));

		try {
			final process = new Process(cmd, args);
			var stdout = process.stdout.readAll().toString();
			var stderr = process.stderr.readAll().toString();
			var returnCode = process.exitCode();
			process.close();
			if (returnCode != 0) {
				Log.error('Haxe returned an error while compiling: $className:\n$stderr');
				return -1;
			}
		} catch (e) {
			Log.error('Haxe returned an error while compiling: $className:\n${e.message}');
			return -1;
		}
		return 0;
	}

	static var ignoredFiles = ["import.hx"];
	static var ignoredDirectories = ["unused", "externs"];
	static var ignoredFilesRegex = new EReg(ignoredFiles.join("|"), "i");
	static var ignoredDirectoriesRegex = new EReg(ignoredDirectories.join("|"), "i");

	static function isIgnored(file:String, ignoreRegexes:Array<EReg>):Bool {
		for (regex in ignoreRegexes) {
			if (regex.match(file)) {
				return true;
			}
		}
		return false;
	}

	static function getFilesRecursive(directory:String = "path/to/"):Array<String> {
		var files:Array<String> = [];

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

	macro static public function generateScriptsList(scriptsDir:String = 'scripts', outputFileName:String):Void {
		// trace("Generating scripts list...");

		var files:Array<String> = getFilesRecursive(scriptsDir);

		if (files == null) {
			trace("No scripts found in " + scriptsDir);
			return;
		}

		// filter out to just the .hx files
		files = files.filter(function(file) {
			return StringTools.endsWith(file, ".hx");
		});

		// ensure the output directory exists
		if (!FileSystem.exists(Path.directory(outputFileName))) {
			FileSystem.createDirectory(Path.directory(outputFileName));
		}
		var f = File.write(outputFileName, false);
		f.writeString("#####################################\n");
		f.writeString('# Auto generated scripts list from ${scriptsDir}\n');
		f.writeString("# Total scripts: " + files.length + "\n");
		f.writeString("#####################################\n");
		f.writeString("\n");
		for (fileName in files) {
			// strip the scriptsDir directory from the file name
			fileName = fileName.substring(scriptsDir.length + 1);
			// strip the .hx extension
			fileName = fileName.substring(0, fileName.length - 3);
			// replace slashes with dots
			fileName = fileName.split("/").join(".");
			f.writeString(fileName + "\n");
			// trace("Added script to list: " + fileName);
		}
		f.close();
	}

	static function trimArgs(args:Array<String>, endOfArgsFlag = "--"):Array<String> {
		// remove any args after '--'
		var endOfArgsIndex = 0;
		while (endOfArgsIndex < args.length) {
			if (args[endOfArgsIndex] == endOfArgsFlag) {
				break;
			}
			endOfArgsIndex++;
		}
		return (args.slice(0, endOfArgsIndex));
	}

	static function getClassNamesFromArgs(args:Array<String>):Array<String> {
		args = trimArgs(args);
		var classNames:Array<String> = [];
		var i = args.length - 1; // Start at the end so we don't cause problems when we remove arguments

		var singleNameFlagList = ['-debug', '--debug'];

		while (i >= 0) {
			if (singleNameFlagList.contains(args[i].toLowerCase())) {
				// remove single name flags (like --debug)
				args.splice(i, 1);
			} else if (StringTools.startsWith(args[i], "-")) {
				// remove any flags that start with '-' (includes '--') (should have two values, like '-cp src', '--lib mylib' )
				args.splice(i, 2);
			}

			i--;
		}

		// Any remaining arguments are script names
		for (j in args) {
			classNames.push(j);
		}

		return classNames;
	}

	macro static public function compileScript(rootDir:String, scriptsDir:String, outputDir:String, classesInfoPath:String, target:String, haxeArgs:Array<String>,
			className:String):Int {
		// strip any preceding '.' from the extension
		if (StringTools.startsWith(target, ".")) {
			target = target.substring(1);
		}

		rootDir = rootDir ?? Sys.getCwd();
		haxeArgs = haxeArgs ?? [];

		var result = compileScriptInternal(rootDir, scriptsDir, outputDir, classesInfoPath, target, haxeArgs, className);

		if (result != 0) {
			Log.error("Failed to compile class: " + className);
		} else {
			Log.debug("Compiled class: " + className);
		}

		return result;
	}

	macro static public function compileScripts(scriptsDir:String = 'scripts', outputDir:String = 'gen', classesInfoPath:String = '.', extension:String = "js"):Void {
		var files = getFilesRecursive(scriptsDir);

		// only include .hx files
		files = files.filter(function(file) {
			return StringTools.endsWith(file, ".hx");
		});

		// additional haxe arguments
		var haxeArgs = [];

		for (fileName in files) {
			// strip the scriptsDir directory from the file name
			fileName = fileName.substring(scriptsDir.length + 1);
			// strip the .hx extension
			fileName = fileName.substring(0, fileName.length - 3);
			// replace slashes with dots
			fileName = fileName.split("/").join(".");

			var result = compileScriptInternal(Sys.getCwd(), scriptsDir, outputDir, classesInfoPath, extension, haxeArgs, fileName);

			if (result != 0) {
				Log.error("Failed to compile class: " + fileName);
			} else {
				Log.info("Compiled class: " + fileName);
			}
		}
	}

	public static function main() {
		Log.setLevel(LogLevel.Debug);
		Log.debug("ScriptCompiler starting");
		Log.rawOutput = true;
		// This is the path of this file?
		// var rootDir = FileSystem.fullPath(Sys.programPath());
		// rootDir = Path.directory(rootDir);

		var rootDir = Sys.getCwd();

		var sourceDirectory = "scripts";
		var classNames = [];
		var outputDirectory = "";
		var target = "js";
		var classesInfoPath = "export_classes.info";

		var args = Sys.args();
		args = trimArgs(args);

		// trace("Arguments: " + args);

		var i = args.length - 1; // Start at the end so we don't cause problems when we remove arguments

		while (i >= 0) {
			var currentArg = args[i].toLowerCase();
			currentArg = StringTools.trim(currentArg);

			if ((currentArg == "-h") || (currentArg == "--help")) {
				Log.info("Usage: haxe --run hxcore.macros.ScriptCompiler [--rootDir | -root] <rootDir> [--sourceDir | -src] <sourceDir> [--outputDir | -out] <outputDir> [--classesInfo | -ci ] <classesInfoFile> [--target | -t] <target> [--class | -c] <className>");
				return;
			} else if ((currentArg == "-src") || currentArg == "--sourcedir") {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a directory argument');
					return;
				}
				sourceDirectory = args[i + 1];
				args.splice(i, 2);
			} else if ((currentArg == "--class") || (currentArg == "--classname") || (currentArg == "-c") || (currentArg == "--script")) {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a class name argument');
					return;
				}
				classNames.push(args[i + 1]);
				args.splice(i, 2);
			} else if ((currentArg == "-out") || (currentArg == "--outputdir")) {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a directory argument');
					return;
				}
				outputDirectory = args[i + 1];
				args.splice(i, 2);
			} else if ((currentArg == "-root") || (currentArg == "--rootdir")) {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a directory argument');
					return;
				}
				rootDir = args[i + 1];
				args.splice(i, 2);
			} else if ((currentArg == "-t") || (currentArg == "--target")) {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a target argument');
					return;
				}
				target = args[i + 1];
				args.splice(i, 2);
			} else if ((currentArg == "-ci") || (currentArg == "--classesinfo")) {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a file path argument');
					return;
				}
				classesInfoPath = args[i + 1];
				args.splice(i, 2);
			}

			i--;
		}

		// Log.debug("Source directory: " + sourceDirectory);
		// Log.debug("Output directory: " + outputDirectory);
		// Log.debug("Target: " + target);

		// Log.debug("Class names: " + classNames);

		if (classNames.length == 0) {
			Log.error("Please specify a class/script name (e.g. [--className | -class | -c | --script] MyScript). The class name (including package) is relative to the [--sourceDir | -src] directory (e.g. MyScript or mygame.MyScript).");
			return;
		}

		if (outputDirectory.length == 0) {
			Log.error("Please specify an output directory (e.g. [--outputDir | -out] bin/cppia/scripts).");
			return;
		}

		// remove leading . if it was included in the extension
		if (StringTools.startsWith(target, ".")) {
			target = target.substring(1);
		}

		// add the hxcore lib
		args.push("-lib");
		args.push("hxcore");

		#if emscripten
		args.push("-D");
		args.push("CPPIA_NO_JIT");
		#end

		for (className in classNames) {
			Log.debug('Compiling ${Path.join([rootDir, sourceDirectory, className + ".hx"])} to ${Path.join([rootDir, outputDirectory, className + "." + target])}...');
			ScriptCompiler.compileScriptInternal(rootDir, sourceDirectory, outputDirectory, classesInfoPath, target, args, className);
		}

		Log.debug("ScriptCompiler finished");
	}
}
