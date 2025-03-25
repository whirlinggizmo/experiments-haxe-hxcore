package hxcore.scripting;

import sys.FileSystem;
import haxe.io.Path;
import hxcore.logging.Log;
import sys.io.File;
import sys.io.Process;

// A script generator that generates "script" files from .hx files
// hxml can't do variables, so we use this
// Usage example: Compile 'Test.hx' in the 'scripts' directory to 'Test.cppia' in the 'bin/cppia/scripts' directory:
// haxe --run hxcore.scripting.ScriptCompiler --scriptDir scripts --scriptName Test --target cppia --outputDir bin/cppia/scripts
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
				final process = new Process(haxeExePath, ['--version']);
				return process.exitCode() == 0;
			} catch (e) {
				return false;
			}
		}

		// check for environment variable HAXEPATH first
		var path = Sys.getEnv("HAXEPATH");
		if (path != null) {
			//Log.info("Found environment variable HAXEPATH: " + path);
			var haxePath = Path.join([path, cmd]);
			if (isValidHaxePath(haxePath)) {
				return haxePath;
			}
			Log.warn('Unable to find $cmd in HAXEPATH: $path, falling back to $lookupCmd...');
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
				return null;
			}
		} catch (e) {
			return null;
		}
	}

	public static function compileScriptInternal(rootDir:String, sourceDir:String, outputDir:String, target:String, haxeArgs:Array<String>,
			className:String):Int {
		if (sourceDir == null) {
			Log.error("Please specify a source directory.");
			return -1;
		}
		if (outputDir == null) {
			Log.error("Please specify an output directory.");
			return -1;
		}

		var cmd = findHaxeExecutable();

		if (cmd == null) {
			Log.error("Unable to find haxe executable");
			return -1;
		}

		if (rootDir == null) {
			rootDir = Sys.getCwd();
		}

		if (!Path.isAbsolute(rootDir)) {
			rootDir = Path.join([Sys.getCwd(), rootDir]);
		}

		if (!Path.isAbsolute(sourceDir)) {
			sourceDir = Path.join([rootDir, sourceDir]);
		}

		if (!Path.isAbsolute(outputDir)) {
			outputDir = Path.join([rootDir, outputDir]);
		}

		rootDir = Path.normalize(rootDir);
		sourceDir = Path.normalize(sourceDir);
		outputDir = Path.normalize(outputDir);

		// strip any preceding '.' from the target (.js -> js, .cppia -> cppia, etc)
		if (StringTools.startsWith(target, ".")) {
			target = target.substring(1);
		}

		// convert package's '.' to '/' for the filename
		var classNameAsPath = StringTools.replace(className, ".", "/");
		var classPath = new Path(classNameAsPath);
		var packagePath = classPath.dir ?? "";
		var outputFileName = classPath.file + '.' + target;
		var outputFileDir = Path.join([ outputDir, packagePath]);
		var outputFilePath = Path.join([outputFileDir, outputFileName]);
		var hxFilePath = Path.join([ sourceDir, classNameAsPath + ".hx"]);

		Log.debug('Compiling class: ${className}');
		Log.debug("Source file: " + hxFilePath);
		Log.debug("Output file: " + outputFilePath);

		// ensure the source path is a valid haxe file
		if (!FileSystem.exists(hxFilePath)) {
			Log.error("Class file not found: " + hxFilePath);
			return -1;
		}

		// create the output directory
		if (!FileSystem.exists(outputFileDir)) {
			FileSystem.createDirectory(outputFileDir);
		}

		//trace("rootDir: " + rootDir);
		//trace("sourceDir: " + sourceDir);

		/*
			var defines = Context.getDefines();
			for (key in defines.keys()) {
				trace("Define: " + key + " = " + defines.get(key));
			}


			Compiler.addClassPath(Path.join([rootDir, sourceDir]));
			//Compiler.include("hxcore");
			//Compiler.define("source-map-content");
			//Compiler.define("source-map");
			//Compiler.define("enable-script-reload");
			//Compiler.define("cppia");
			//Compiler.define("dce", "no");

			Compiler.define("OUTPUT_FILE", outputFilePath);
			Compiler.define("CLASS_NAME", className);
		 */

		// compile the script
		var classInfoFile = Path.join([sourceDir, "export_classes.info"]);

		if (!FileSystem.exists(classInfoFile)) {
			Log.error("Class info file not found: " + classInfoFile);
			return -1;
		} else {
			//Log.info("Class info file found: " + classInfoFile);
		}

		var args = ["-cp", sourceDir, "-lib", "hxcore", "-D", 'dll_import=$classInfoFile'];

		// disable jit for emscripten
		if (target == "emscripten") {
			args.push("-D");
			args.push("CPPIA_NO_JIT");
		}

		// this should already have been done, but just in case
		haxeArgs = trimArgs(haxeArgs);

		// add the haxe args from the command line
		args = args.concat(haxeArgs);

		// add the target
		args.push('-${target}');

		// add the output file
		args.push('${outputFilePath}');

		// add the class name
		args.push('${className}');

		Log.debug("Command: " + cmd);
		Log.debug("Args: " + args);

		var result = Sys.command(cmd, args);
		if (result != 0) {
			Log.error("Failed to compile class: " + className);
			return result;
		}

		//Log.info('Compiled class: ${className}');

		return result;
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

	macro static public function compileScript(rootDir:String, scriptsDir:String, outputDir:String, target:String, haxeArgs:Array<String>,
			className:String):Int {
		// strip any preceding '.' from the extension
		if (StringTools.startsWith(target, ".")) {
			target = target.substring(1);
		}

		rootDir = rootDir ?? Sys.getCwd();
		haxeArgs = haxeArgs ?? [];

		var result = compileScriptInternal(rootDir, scriptsDir, outputDir, target, haxeArgs, className);

		if (result != 0) {
			Log.error("Failed to compile class: " + className);
		} else {
			Log.debug("Compiled class: " + className);
		}

		return result;
	}

	macro static public function compileScripts(scriptsDir:String = 'scripts', outputDir:String = 'gen', extension:String = "js"):Void {
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

			var result = compileScriptInternal(Sys.getCwd(), scriptsDir, outputDir, extension, haxeArgs, fileName);

			if (result != 0) {
				Log.error("Failed to compile class: " + fileName);
			} else {
				Log.info("Compiled class: " + fileName);
			}
		}
	}

	public static function main() {
		Log.setLevel(LogLevel.Info);
		Log.debug("ScriptCompiler starting");
		Log.rawOutput = true;
		// This is the path of this file?
		//var rootDir = FileSystem.fullPath(Sys.programPath());
		//rootDir = Path.directory(rootDir);
		
		var rootDir = Sys.getCwd();

		var sourceDirectory = "scripts";
		var classNames = [];
		var outputDirectory = "";
		var target = "js";

		var args = Sys.args();
		args = trimArgs(args);

		//trace("Arguments: " + args);

		var i = args.length - 1; // Start at the end so we don't cause problems when we remove arguments

		while (i >= 0) {
			var currentArg = args[i].toLowerCase();
			currentArg = StringTools.trim(currentArg);

			if ((currentArg == "-h") || (currentArg == "--help")) {
				Log.info("Usage: haxe --run hxcore.macros.ScriptCompiler [--sourceDir | -src] <sourceDir> [--outputDir | -out] <outputDir> [--target | -t] <target> [--class | -c] <className>");
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
			} else if ((currentArg == "-root") || (currentArg == "--rootDir")) {
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
			}

			i--;
		}

		//trace("Source directory: " + sourceDirectory);
		//trace("Output directory: " + outputDirectory);
		//trace("Target: " + target);

		//trace("Class names: " + classNames);

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
			Log.debug('Compiling ${Path.join([sourceDirectory, className + ".hx"])} to ${Path.join([outputDirectory, className + "." + target])}...');
			ScriptCompiler.compileScriptInternal(rootDir, sourceDirectory, outputDirectory, target, args, className);
		}

		Log.debug("ScriptCompiler finished");
	}
}
