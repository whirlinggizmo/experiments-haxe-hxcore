package tests.scripting;

#if cpp
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import hxcore.util.ExportClassesInfoFilter;
import hxcore.scripting.ScriptCompiler;

/**
 * Base class providing common utilities for Cppia HCR integration tests.
 */
class CppiaHcrTestBase {
	/**
	 * Locates the export_classes.info file in common build locations.
	 */
	public static function findExportClassesInfo():String {
		var cwd = Sys.getCwd();
		var candidates = [
			Path.join([cwd, "export_classes.info"]),
			Path.join([cwd, "bin", "tests-cpp", "export_classes.info"]),
			Path.join([cwd, "out", "tests-cpp", "export_classes.info"])
		];
		for (path in candidates) {
			if (FileSystem.exists(path)) return path;
		}
		return null;
	}

	/**
	 * Sets up temp directories for a test.
	 * Returns object with baseDir, scriptsDir, outputDir.
	 */
	public static function setupTestDirs(testName:String):{baseDir:String, scriptsDir:String, outputDir:String} {
		var tmpRoot = Sys.getEnv("TMPDIR");
		if (tmpRoot == null || tmpRoot.length == 0) tmpRoot = "/tmp";
		var baseDir = Path.join([tmpRoot, testName]);
		var scriptsDir = Path.join([baseDir, "scripts"]);
		var outputDir = Path.join([baseDir, "gen"]);

		// Clean up any previous run
		if (FileSystem.exists(baseDir)) {
			removeDirectoryRecursive(baseDir);
		}

		FileSystem.createDirectory(baseDir);
		FileSystem.createDirectory(scriptsDir);
		FileSystem.createDirectory(outputDir);

		return {baseDir: baseDir, scriptsDir: scriptsDir, outputDir: outputDir};
	}

	/**
	 * Creates filtered export_classes.info for given class patterns.
	 */
	public static function createFilteredInfo(scriptsDir:String, exportInfoPath:String, patterns:Array<String>):String {
		var filteredInfoPath = Path.join([scriptsDir, "export_classes.filtered.info"]);
		var filtered = ExportClassesInfoFilter.filterContent(File.getContent(exportInfoPath), patterns);
		File.saveContent(filteredInfoPath, filtered);
		return filteredInfoPath;
	}

	/**
	 * Compiles a single script to .cppia.
	 */
	public static function compileScript(baseDir:String, scriptsDir:String, outputDir:String, filteredInfoPath:String, className:String):Int {
		var haxeArgs = ["-cp", baseDir];
		// Extract the output folder name from the outputDir path (e.g., "gen" from "/tmp/.../gen")
		var outputFolder = Path.withoutDirectory(outputDir);
		return ScriptCompiler.compileScriptInternal(baseDir, "scripts", outputFolder, filteredInfoPath, "cppia", haxeArgs, className);
	}

	/**
	 * Script source templates.
	 */
	public static function externalScriptSource(marker:String):String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class Test extends Script {",
			"  public function new() { super(); }",
			'  public function getMarker():String return "' + marker + '"; ',
			"}"
		].join("\n");
	}

	public static function dependencyScriptSource(marker:String):String {
		return [
			"package scripts;",
			"class Dep {",
			'  public static function marker():String return "' + marker + '";',
			"}"
		].join("\n");
	}

	public static function dependentScriptSource():String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class Test extends Script {",
			"  public function new() { super(); }",
			"  public function getMarker():String return Dep.marker();",
			"}"
		].join("\n");
	}

	public static function loaderScriptSource():String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class Test extends Script {",
			"  public function new() { super(); }",
			"  public function getMarker():String return 'loader';",
			"}"
		].join("\n");
	}

	public static function newScriptSource(marker:String):String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class NewScript extends Script {",
			"  public function new() { super(); }",
			"  public function getMarker():String return '" + marker + "';",
			"}"
		].join("\n");
	}

	/**
	 * Recursively removes a directory.
	 */
	public static function removeDirectoryRecursive(path:String):Void {
		if (!FileSystem.exists(path)) return;
		if (FileSystem.isDirectory(path)) {
			for (entry in FileSystem.readDirectory(path)) {
				removeDirectoryRecursive(Path.join([path, entry]));
			}
			FileSystem.deleteDirectory(path);
		} else {
			FileSystem.deleteFile(path);
		}
	}
}
#end
