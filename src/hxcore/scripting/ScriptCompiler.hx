package hxcore.scripting;

import cpp.cppia.HostClasses;
import sys.io.FileSeek;
import hxcore.logging.Log;
import sys.FileSystem;
import haxe.io.Path;
import hxcore.util.PathUtils;
import sys.io.File;
import sys.io.Process;

// import hxcore.scripting.ScriptLoader;
// A script generator that generates "script" files from .hx files
// Usage example: Compile 'scripts/Test.hx' in the 'scripts' directory to 'scripts/Test.cppia' in the 'dist/scripts' directory:
// haxe --run hxcore.scripting.ScriptCompiler --scriptDir scripts --scriptName scripts.Test --target cppia --outputDir dist
@:keep
class ScriptCompiler {
	private static var generatedScriptNamespace:String = "gen";

	public static function getGeneratedScriptNamespace():String {
		return generatedScriptNamespace;
	}

	public static function setGeneratedScriptNamespace(namespace:String):Void {
		generatedScriptNamespace = namespace;
		Log.debug('Generated script namespace set to: $namespace');
	}

	/**
	 * Compiles a script using macro-based namespace injection instead of temporary files.
	 * It uses :native metadata to inject namespaces.
	 */
	public static function compileScriptInternal(rootDir:String, sourceDir:String, outputDir:String, classesInfoPath:String, target:String,
			haxeArgs:Array<String>, className:String):Int {
		if (sourceDir == null) {
			Log.error("Please specify a source directory (e.g. 'scripts').");
			return -1;
		}
		if (outputDir == null) {
			Log.error("Please specify an output directory (e.g. 'gen/scripts').");
			return -1;
		}

		if (className == null) {
			Log.error("Please specify a class name (e.g. 'Test' for scripts/Test.hx).");
			return -1;
		}

		if (rootDir == null || rootDir.length == 0) {
			rootDir = Sys.getCwd();
		} else if (!Path.isAbsolute(rootDir)) {
			rootDir = PathUtils.normalizePath(Path.join([Sys.getCwd(), rootDir]));
		}
		rootDir = PathUtils.normalizePath(rootDir);
		sourceDir = PathUtils.makeAbsolutePath(rootDir, sourceDir);
		outputDir = PathUtils.makeAbsolutePath(rootDir, outputDir);
		classesInfoPath = PathUtils.makeAbsolutePath(rootDir, classesInfoPath);

		rootDir = rootDir.length > 0 ? Path.addTrailingSlash(rootDir) : rootDir;
		sourceDir = sourceDir.length > 0 ? Path.addTrailingSlash(sourceDir) : sourceDir;
		outputDir = outputDir.length > 0 ? Path.addTrailingSlash(outputDir) : outputDir;

		if (StringTools.startsWith(target, "."))
			target = target.substring(1);

		var classNameAsPath = StringTools.replace(className, ".", "/");
		var classPath = new Path(classNameAsPath);
		var packagePath = classPath.dir ?? "";
		var outputFileName = '${classPath.file}.$target';
		var outputFileDir = Path.join([outputDir, packagePath]);
		var outputFilePath = Path.join([outputFileDir, outputFileName]);
		var hxFilePath = Path.join([rootDir, classNameAsPath + ".hx"]);

		Log.debug('Compiling class with macro injection: $className');
		Log.debug('Root dir: $rootDir');
		Log.debug('Source file: $hxFilePath');
		Log.debug('Output file: $outputFilePath');
		Log.debug('ClassesInfo file: $classesInfoPath');

		// Validate paths
		if (FileSystem.exists(rootDir) && !FileSystem.isDirectory(rootDir)) {
			Log.error('Root directory is not a directory: $rootDir');
			return -1;
		}
		if (FileSystem.exists(sourceDir) && !FileSystem.isDirectory(sourceDir)) {
			Log.error('Source directory is not a directory: $sourceDir');
			return -1;
		}

		if (!FileSystem.exists(classesInfoPath) || FileSystem.isDirectory(classesInfoPath)) {
			Log.error('Classes info file is not a file: $classesInfoPath');
			return -1;
		}

		if (!FileSystem.exists(hxFilePath) || FileSystem.isDirectory(hxFilePath)) {
			Log.error('Class file not found: $hxFilePath');
			return -1;
		}

		if (!FileSystem.exists(outputFileDir)) {
			Log.debug('Creating output directory: $outputFileDir');
			FileSystem.createDirectory(outputFileDir);
		}

		var haxeExecutable = PathUtils.findHaxeExecutablePath();
		if (haxeExecutable == null) {
			Log.error('Unable to find haxe executable');
			return -1;
		}

		function addFlag(args:Array<String>, flag:String, value:String = null) {
			args.push(flag);
			if (value != null) {
				args.push(value);
			}
		}

		function addValue(args:Array<String>, value:String) {
			args.push(value);
		}

		function addExclusiveFlag(args:Array<String>, flag:String, value:String = null) {
			if (args.contains(flag)) {
				Log.debug('Flag already in args, skipping: $flag');
				return;
			}
			args.push(flag);
			if (value != null) {
				args.push(value);
			}
		}

		function addDefine(args:Array<String>, define:String, value:String = null) {
			args.push("-D");
			if (value != null) {
				args.push('${define}=${value}');
			} else {
				args.push(define);
			}
		}

		function addClassPath(args:Array<String>, classPath:String) {
			args.push("-cp");
			args.push(classPath);
		}

		var args = [];

		// Include passed in haxe arguments
		for (haxeArg in haxeArgs) {
			args.push(haxeArg);
		}

		// dead code elimination
		// Note to self: WHY DOES THIS CAUSE PROBLEMS?  cppia generates something weird when it's enabled, and it breaks the script compilation
		// args.push("--dce");
		// args.push("no");

		// us!
		args.push("--library");
		args.push("hxcore");

		// class path for root directory
		args.push("-cp");
		args.push(rootDir);

		// the classes info path (as a define)
		args.push("-D");
		args.push('dll_import=$classesInfoPath');

		// no jit for emscripten :(
		#if emscripten
		args.push("-D");
		args.push("CPPIA_NO_JIT");
		#end

		if (target == "cppia") {
			args.push("-D");
			args.push("cppia");
		}

		// add a macro to force include the original class name
		var includeMacroArgs = ' "${className}", true ';
		args.push("--macro");
		args.push('include(${includeMacroArgs})');

		// add our macro to change the namespace to the generated namespace
		var setNativeMacroArgs = ' "${className}", "${generatedScriptNamespace}.${className}" ';
		args.push("--macro");
		args.push('hxcore.macros.NamespaceInjector.setNative(${setNativeMacroArgs})');

		// the target (cppia, js, etc)
		// output path must align with outputDir to avoid loader/watch mismatches
		args.push('--${target}');
		args.push(outputFilePath);

		// and the class to compile
		args.push(className);

		Log.debug('Haxe executable: ${haxeExecutable}');
		Log.debug('Args: ${args}');
		Log.debug('Full command: ${haxeExecutable} ${args.join(" ")}');

		// debugging
		// var hardCodedArgs = ["-lib", "hxcore", "--macro", "hxcore.macros.NamespaceInjector.setNative(\"scripts.Test\",\"gen.scripts.Test\")", "--cppia", "gen/scripts/Test.cppia", "scripts.Test"];
		// Log.debug('Hardcoded command: ' + haxeExecutable + ' ' + hardCodedArgs.join(" "));

		// HostClasses.exclude("hxcore");

		try {
			final process = new Process(haxeExecutable, args);
			// final process = new Process(haxeExecutable, hardCodedArgs);
			var stdout = process.stdout.readAll().toString();
			var stderr = process.stderr.readAll().toString();
			var returnCode = process.exitCode();
			Log.debug('stdout: ' + stdout);
			Log.debug('stderr: ' + stderr);
			Log.debug('returnCode: ' + returnCode);
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

	macro static public function generateScriptsList(scriptsDir:String = 'scripts', outputFileName:String):Void {
		// trace("Generating scripts list...");
		final ignoredFiles = ["import.hx"];
		final ignoredDirectories = ["unused", "externs"];

		var files:Array<String> = PathUtils.getFilesRecursive(scriptsDir, ignoredFiles, ignoredDirectories);

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
		// remove any args after the end of args flag.  This includes removing the end of args flag itself
		var trimmedArgs = [];
		for (arg in args) {
			if (arg == endOfArgsFlag) {
				break;
			}
			trimmedArgs.push(arg);
		}
		return trimmedArgs;
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

	macro static public function compileScript(rootDir:String, scriptsDir:String, outputDir:String, classesInfoPath:String, targetType:String,
			haxeArgs:Array<String>, className:String):Int {
		// strip any preceding '.' from the extension (.cppia -> cppia)
		if (StringTools.startsWith(targetType, ".")) {
			targetType = targetType.substring(1);
		}

		if (rootDir == null || rootDir.length == 0 || rootDir == "." || rootDir == "./") {
			rootDir = Sys.getCwd();
		}
		haxeArgs = haxeArgs ?? [];

		var result = compileScriptInternal(rootDir, scriptsDir, outputDir, classesInfoPath, targetType, haxeArgs, className);

		if (result != 0) {
			Log.error("Failed to compile class: " + className);
		} else {
			Log.debug("Compiled class: " + className);
		}

		return result;
	}

	macro static public function compileScriptFromFilename(filename:String, scriptsDir:String = 'scripts', outputDir:String = 'gen',
			classesInfoPath:String = 'export_classes.filtered.info', target:String = "cppia"):Void {
		// Parse filename into package structure
		// e.g., "ui/Button.hx" -> package "ui", className "Button"
		// e.g., "game/player/Player.hx" -> package "game.player", className "Player"
		// e.g., "Test.hx" -> package "", className "Test"

		var pathParts = filename.split("/");
		var fileName = pathParts[pathParts.length - 1];
		var packagePath = pathParts.slice(0, pathParts.length - 1);

		// Remove .hx extension
		if (StringTools.endsWith(fileName, ".hx")) {
			fileName = fileName.substring(0, fileName.length - 3);
		}

		// Create package name from path
		var packageName = packagePath.join(".");
		var className = packageName.length > 0 ? packageName + "." + fileName : fileName;

		Log.info('Compiling script from filename: $filename');
		Log.info('Package: $packageName, Class: $className');

		// Compile the script
		var result = compileScriptInternal(Sys.getCwd(), scriptsDir, outputDir, classesInfoPath, target, [], className);

		if (result != 0) {
			Log.error("Failed to compile script from filename: " + filename);
		} else {
			Log.info("Successfully compiled script from filename: " + filename);
		}
	}

	macro static public function compileScripts(rootDir:String = '.', scriptsDir:String = 'scripts', outputDir:String = 'gen',
			classesInfoPath:String = 'export_classes.filtered.info', extension:String = "cppia"):Void {
		
		Log.setLevel(Warning);
		if (!Path.isAbsolute(rootDir)) {
			rootDir = sys.FileSystem.absolutePath(rootDir);
		}

		var files = PathUtils.getFilesRecursive(Path.join([rootDir, scriptsDir]));

		// trace('FOUND ${files.length} Script files');

		// only include .hx files
		files = files.filter(function(file) {
			return StringTools.endsWith(file, ".hx");
		});

		// additional haxe arguments
		var haxeArgs = [];

		for (fileName in files) {
			// strip the root directory
			Log.debug(fileName);
			fileName = PathUtils.relativePath(rootDir, fileName);
			Log.debug(fileName);
			// normalize it to remove leading ./
			fileName = PathUtils.normalizePath(fileName);
			Log.debug(fileName);
			// strip the scriptsDir directory from the file name
			// fileName = fileName.substring(scriptsDir.length + 1);
			// Log.debug(fileName);
			// strip the .hx extension
			fileName = fileName.substring(0, fileName.length - 3);
			Log.debug(fileName);
			// replace slashes with dots
			fileName = fileName.split("/").join(".");
			Log.debug(fileName);

			var result = compileScriptInternal(rootDir, scriptsDir, outputDir, classesInfoPath, extension, haxeArgs, fileName);

			if (result != 0) {
				Log.error("Failed to compile class: " + fileName);
			} else {
				Log.info("Compiled class: " + fileName);
			}
		}
	}

	public static function main() {
		Log.setLevel(LogLevel.Warning);
		Log.debug("ScriptCompiler starting");
		// This is the path of this file?
		// var rootDir = FileSystem.fullPath(Sys.programPath());
		// rootDir = Path.directory(rootDir);

		var rootDir = Sys.getCwd();

		var sourceDirectory = "scripts";
		var classNames = [];
		var outputDirectory = "";
		var target = "js";
		var classesInfoPath = "export_classes.filtered.info";

		var args = Sys.args();
		args = trimArgs(args);

		// trace("Arguments: " + args);

		var i = args.length - 1; // Start at the end so we don't cause problems when we remove arguments

		while (i >= 0) {
			var currentArg = args[i].toLowerCase();
			currentArg = StringTools.trim(currentArg);

			if ((currentArg == "-h") || (currentArg == "--help")) {
				Log.info("Usage: haxe --run hxcore.scripting.ScriptCompiler [options]");
				Log.info("Options:");
				Log.info("  --rootDir | -root <dir>     Root directory");
				Log.info("  --sourceDir | -src <dir>    Source directory");
				Log.info("  --outputDir | -out <dir>    Output directory");
				Log.info("  --classesInfo | -ci <file>  Classes info file");
				Log.info("  --target | -t <target>      Target (cppia, js, etc.)");
				Log.info("  --class | -c <className>     Class name to compile");
				Log.info("  --file | -f <filename>      Filename to compile (parses into package.class)");
				Log.info("");
				Log.info("Examples:");
				Log.info("  haxe --run hxcore.scripting.ScriptCompiler --file ui/Button.hx");
				Log.info("  haxe --run hxcore.scripting.ScriptCompiler --class Test");
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
			} else if ((currentArg == "--file") || (currentArg == "-f") || (currentArg == "--filename")) {
				if (args.length < i + 2) {
					Log.error('Error: ${args[i]} requires a filename argument');
					return;
				}
				var filename = args[i + 1];
				// Parse filename into package structure
				var pathParts = filename.split("/");
				var fileName = pathParts[pathParts.length - 1];
				var packagePath = pathParts.slice(0, pathParts.length - 1);

				// Remove .hx extension
				if (StringTools.endsWith(fileName, ".hx")) {
					fileName = fileName.substring(0, fileName.length - 3);
				}

				// Create package name from path
				var packageName = packagePath.join(".");
				var className = packageName.length > 0 ? packageName + "." + fileName : fileName;

				Log.info('Compiling script from filename: $filename');
				Log.info('Package: $packageName, Class: $className');

				classNames.push(className);
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
