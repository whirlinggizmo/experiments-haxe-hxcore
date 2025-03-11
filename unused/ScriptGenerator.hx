package core.macros;

import sys.io.File;
import sys.FileSystem;
import sys.io.FileOutput;
import haxe.io.Path;

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

function getFilesRecursive(directory:String = "path/to/"):Array<String> {
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

function outputScriptFile(fileName, outputDir) {
	// trace("Outputting script file: " + fileName);
	if (StringTools.endsWith(fileName, ".hx") && !isIgnored(fileName, [ignoredFilesRegex])) {
		var scriptPath = fileName;
		var scriptContent = File.getContent(scriptPath);
		var scriptNameWithExtension = Path.withoutDirectory(scriptPath);
		var scriptName = Path.withoutExtension(scriptNameWithExtension);
		var className = scriptName;

		// trace("Generating script from " + fileName);

		// Wrap the script content into a class
		/*
			var prettyScriptContent = "\n";
			var lines = scriptContent.split("\n");
			for (k => line in lines) {
				// if this line starts with 'function' (ignoring whitespace), add 'public' access modifier to it
				// var r = ~/^\s*function\s+/;
				// line = r.replace(line, 'public function ');
				if (k < lines.length - 1) {
					prettyScriptContent = prettyScriptContent + "\t" + line + '\n';
				} else {
					prettyScriptContent = prettyScriptContent + "\t" + line;
				}
			}
			var classContent = '@:keep\n@:keepSub\n@:expose\nclass ${className} extends Script {${prettyScriptContent}}';
		 */

		// No class wrapper

		var lines = scriptContent.split("\n");
		var prettyScriptContent = "";

		// check for a package declaration.  If we found it, add the import statement after it
		var packageExpr = ~/^\s*package\s+/;
		var classExpr = ~/^\s*class\s+/;

		for (k => line in lines) {
			/*
				if (packageExpr.match(line)) {
					line = line + "\n\nimport scripting.Script;";
					prettyScriptContent = "";
					// break;
				}
			 */

			// if this line starts with 'class' (ignoring whitespace), add '@:expose, @:keep, @:keepSub' access modifiers to it
			line = classExpr.replace(line, '@:keep\n@:keepSub\n@:expose\nclass ');

			if (k < lines.length - 1) {
				prettyScriptContent = prettyScriptContent + line + "\n";
			} else {
				prettyScriptContent = prettyScriptContent + line;
			}
		}
		var classContent = prettyScriptContent;

		// Write the new class to the output directory
		var outputPath = outputDir + "/" + fileName;
		if (!FileSystem.exists(Path.directory(outputPath))) {
			FileSystem.createDirectory(Path.directory(outputPath));
		}
		File.saveContent(outputPath, classContent);
	} else {
		trace("Skipping file: " + fileName);
	}
}

class ScriptGenerator {
	macro static public function generateScripts(scriptsDir:String = 'scripts', outputDir:String = 'gen'):Void {
		// scriptsDir = "../scripts";
		// var outputDir = "../scripts-gen";

		var files = getFilesRecursive(scriptsDir);

		for (fileName in files) {
			outputScriptFile(fileName, outputDir);
		}
	}

	macro static public function generateScript(fileName:String, outputDir:String = 'gen'):Void {
		outputScriptFile(fileName, outputDir);
	}

	macro static public function generateScriptsList(scriptsDir:String = 'gen', outputFileName:String):Void {
		// trace("Generating scripts list...");

		var files = getFilesRecursive(scriptsDir);

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
			// only include .hx files
			if (!StringTools.endsWith(fileName, ".hx")) {
				continue;
			}
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
}
