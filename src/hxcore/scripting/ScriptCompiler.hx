package hxcore.scripting;

import sys.io.FileSeek;
import haxe.Log;
import sys.FileSystem;
import haxe.io.Path;
import hxcore.logging.Log;
import hxcore.util.PathUtils;
import sys.io.File;
import sys.io.Process;

// import hxcore.scripting.ScriptLoader;
// A script generator that generates "script" files from .hx files
// hxml can't do variables, so we use this
// Usage example: Compile 'Test.hx' in the 'scripts' directory to 'Test.cppia' in the 'dist/scripts' directory:
// haxe --run hxcore.scripting.ScriptCompiler --scriptDir scripts --scriptName scripts.Test --target cppia --outputDir dist/scripts
@:keep
class ScriptCompiler {
	private static var generatedScriptNamespace:String = "gen";

	public static function getGeneratedScriptNamespace():String {
		return generatedScriptNamespace;
	}

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
		return null;
	}

	private static function ensureAbsolute(base:String, path:String):String {
		return Path.isAbsolute(path) ? Path.normalize(path) : Path.normalize(Path.join([base, path]));
	}

	private static function addParentPackageToModule(modulePath:String, parentPackageName:String):Bool {
		if (!FileSystem.exists(modulePath)) {
			Log.error('Module file not found: $modulePath');
			return false;
		}
		// read the module file into memory
		var file = File.read(modulePath, false);
		var fileBytes = file.readAll();
		file.close();

		if (fileBytes.length == 0) {
			Log.error('Module file is empty: $modulePath');
			return false;
		}

		// convert the file bytes to a string
		var fileContent = fileBytes.toString();
		if (fileContent == null) {
			Log.error('Failed to convert module file to string: $modulePath');
			return false;
		}

		// add the parent package name to the module file.  if it doesn't have a package declaration, add it
		// find the line with the package declaration
		// we'll have to use a regex to find the line with the package declaration
		// we're looking for "package" as the start of the line (ignoring preceeding whitespace)
		// we need to replace the line with the package declaration:
		// package; -> package gen;
		// package ; -> package gen;
		// package mine; -> package gen.mine;
		// package mine   ; -> package gen.mine;
		// or no package declaration at all -> package gen;

		// Regex to match package declaration at start of line (ignoring whitespace)
		var packageRegex = new EReg("^\\s*package\\s*([^;\\s]*)\\s*;", "m");

		if (packageRegex.match(fileContent)) {
			// Found existing package declaration
			var existingPackage = packageRegex.matched(1);
			var newPackageDeclaration:String;

			if (existingPackage == null || existingPackage.length == 0) {
				// package; -> package gen;
				newPackageDeclaration = 'package $parentPackageName;';
			} else {
				// package mine; -> package gen.mine;
				newPackageDeclaration = 'package $parentPackageName.$existingPackage;';
			}

			// Replace the existing package declaration
			fileContent = packageRegex.replace(fileContent, newPackageDeclaration);
			Log.debug('Updated package declaration: $newPackageDeclaration');
		} else {
			// No package declaration found, add one at the beginning
			var newPackageDeclaration = 'package $parentPackageName;\n';
			fileContent = newPackageDeclaration + fileContent;
			Log.debug('Added new package declaration: $newPackageDeclaration');
		}

		// write the module file back to disk
		var file = File.write(modulePath, false);
		if (file == null) {
			Log.error('Failed to write module file: $modulePath');
			return false;
		}
		file.writeString(fileContent);
		file.close();
		return true;
	}

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
		// var hxFilePath = Path.join([sourceDir, classNameAsPath + ".hx"]);
		var hxFilePath = Path.join([rootDir, classNameAsPath + ".hx"]);

		var outputFileDir = Path.join([outputDir, packagePath]);
		var outputFilePath = Path.join([outputFileDir, outputFileName]);
		var tempDirBase = ""; // "__temp__";

		Log.debug('Compiling class: $className');
		Log.debug('Root dir: $rootDir');
		Log.debug('Source file: $hxFilePath');
		Log.debug('Output file: $outputFilePath');
		Log.debug('ClassesInfo file: $classesInfoPath');

		// check to make sure directories are actually directories
		if (FileSystem.exists(rootDir) && !FileSystem.isDirectory(rootDir)) {
			Log.error('Root directory is not a directory: $rootDir');
			return -1;
		}
		if (FileSystem.exists(sourceDir) && !FileSystem.isDirectory(sourceDir)) {
			Log.error('Source directory is not a directory: $sourceDir');
			return -1;
		}

		// ensure files are actually files
		if (!FileSystem.exists(classesInfoPath) || FileSystem.isDirectory(classesInfoPath)) {
			Log.error('Classes info file is not a file: $classesInfoPath');
			return -1;
		}

		if (!FileSystem.exists(hxFilePath) || FileSystem.isDirectory(hxFilePath)) {
			Log.error('Class file not found: $hxFilePath');
			return -1;
		}

		if (FileSystem.exists(outputFilePath)) {
			FileSystem.deleteFile(outputFilePath);
		}

		if (!FileSystem.exists(outputFileDir)) {
			Log.debug('Creating output directory: $outputFileDir');
			FileSystem.createDirectory(outputFileDir);
		}

		var cmd = findHaxeExecutable();
		if (cmd == null) {
			Log.error('Unable to find haxe executable');
			return -1;
		}

		/*
			 Since haxe won't honor a cppia-based class replacing an existing class, we have to do some trickery
			For example, if the user included scripts/Test.hx in their build.hxml (making it part of the build), 
			and also compiled it during runtime to gen/scripts/Test.cppia, those two files would have the same package name.
			Since haxe (at least cppia) won't honor the dynamically instantiated class over a statically compiled class,
			we have to do some trickery if we want to be able to override/replace the statically compiled class during runtime.

			Example:
				sourceDir: "scripts" 
				outputDir: "dist/scripts"
				tempDir: "__temp__"
				generatedScriptNamespace: "gen"
				className: "scripts.Test" (scripts/Test.hx)
				target: "cppia"

				1) Create a temporary directory with a subdirectory of the generated script namespace 
				(e.g. "__temp__/gen")
				2) Copy the source file (className + ".hx") to this subdirectory, with the relative directory structure intact
				(e.g. "__temp__/gen/scripts/Test.hx")
				3) Inject the generated script namespace into the temporary source file's package declaration. (e.g. "package scripts;" > "package gen.scripts;")
				4) Add the temporary directory as a class path to the haxeArgs. (--cp __temp__)
				5) Add the generated script namespace to the class name we pass to haxe (e.g. "scripts.Test" > "gen.scripts.Test")
				6) Compile the temporary source file to the output directory.  (creating "dist/scripts/Test.cppia")
				7) Delete the temporary directory
				
				Now the ScriptLoader can load the compiled file from the output directory and the package name will be different than 
				the original package name (so both can exist simultaneously) by resolving the different package names.
				Example ScriptLoader code:
				 
				// Try to load the generated class
				var className = "scripts.Test";
				var data = sys.io.File.getBytes("dist/scripts/Test.cppia").getData();
				var module = Module.fromData(data); 
				module.boot();
				module.run();
				resolvedClass = module.resolveClass("gen." + className); -> the runtime loaded (cppia) class
				if (resolvedClass == null) {
					resolvedClass = Type.resolveClass("scripts.Test"); -> the compiled (.hx) class
				}			
		 */

		var args = ["-cp", sourceDir, "-lib", "hxcore", "-D", 'dll_import=$classesInfoPath'];

		try {
			// create a temporary directory with a subdirectory of the source directory
			var tempDir = Path.join([rootDir, tempDirBase, generatedScriptNamespace]);
			if (!FileSystem.exists(tempDir)) {
				Log.debug('Creating temporary directory: $tempDir');
				FileSystem.createDirectory(tempDir);
			} else {
				Log.debug('Temporary directory already exists: $tempDir');
			}

			// copy the source file to the temporary directory, including the relative directory structure
			var tempFilePath = Path.join([tempDir, classNameAsPath + ".hx"]);

			// create the directory structure in the temporary directory
			var tempFileDir = Path.directory(tempFilePath);
			if (!FileSystem.exists(tempFileDir)) {
				Log.debug('Creating temporary directory structure: $tempFileDir');
				FileSystem.createDirectory(tempFileDir);
			}

			if (FileSystem.exists(tempFilePath)) {
				FileSystem.deleteFile(tempFilePath);
			}
			Log.debug('Copying source file to temporary directory: $hxFilePath -> $tempFilePath');
			File.copy(hxFilePath, tempFilePath);

			// add the parent package name to the module file
			if (!addParentPackageToModule(tempFilePath, generatedScriptNamespace)) {
				Log.error('Failed to add parent package name to module file: $tempFilePath');
				return -1;
			}

			// add the temporary directory to the class path
			args.push("-cp");
			args.push(Path.join([rootDir, tempDirBase]));

			// add the generated script namespace to the class name
			className = generatedScriptNamespace + "." + className;

			// copy the import.hx file to the temporary directory, if it exists
			var importFilePath = Path.join([sourceDir, "import.hx"]);
			if (FileSystem.exists(importFilePath)) {
				File.copy(importFilePath, Path.join([tempDir, "import.hx"]));
			}
		} catch (e) {
			Log.error('Failed to copy source file to temporary directory: $hxFilePath');
			Log.error('Error: ${e.message}');
			return -1;
		}

		#if emscripten
		args.push("-D");
		args.push("CPPIA_NO_JIT");
		#end
		args = args.concat(trimArgs(haxeArgs));
		args = args.concat(['-$target', outputFilePath, className]);

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

		// now that we successfully compiled the script, let's do some small changes to the generated script if it was .cppia
		if (target == "cppia") {
			// find the name of the source file in the script and change it to the original script name
			var stringToReplace = Path.join(['./', tempDirBase, classNameAsPath + ".hx"]);
			var stringToReplaceWith = Path.join([sourceDir, classNameAsPath + ".hx"]);
			Log.debug('Replacing string in file: $outputFilePath');
			Log.debug('String to replace: $stringToReplace');
			Log.debug('String to replace with: $stringToReplaceWith');
			var fileIn = File.read(outputFilePath, true);
			if (fileIn == null) {
				Log.error('Failed to open file for reading: $outputFilePath');
				return -1;
			}
			var fileInBytes = fileIn.readAll();
			fileIn.close();
			if (fileInBytes.length == 0) {
				Log.error('File is empty: $outputFilePath');
				return -1;
			}
			// replace the path to the modified source file with the path to the original source file
			/*fileContent = StringTools.replace(fileContent, stringToReplace, stringToReplaceWith);
				var fileOut = File.write(outputFilePath, false);
				if (fileOut == null) {
					Log.error('Failed to open file for writing: $outputFilePath');
					return -1;
				}
				fileOut.writeString(fileContent);
				fileOut.close();
				Log.debug('Replaced string in file: $outputFilePath');
			 */
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

	macro static public function compileScript(rootDir:String, scriptsDir:String, outputDir:String, classesInfoPath:String, target:String,
			haxeArgs:Array<String>, className:String):Int {
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

	macro static public function compileScriptFromFilename(filename:String, scriptsDir:String = 'scripts', outputDir:String = 'gen',
			classesInfoPath:String = '.', target:String = "cppia"):Void {
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

	macro static public function compileScripts(scriptsDir:String = 'scripts', outputDir:String = 'gen', classesInfoPath:String = '.',
			extension:String = "js"):Void {
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
