package tests.scripting;

#if cpp
import utest.Test;
import utest.Assert;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.Timer;
import haxe.MainLoop;
import hxcore.util.ExportClassesInfoFilter;
import hxcore.scripting.ScriptCompiler;
import hxcore.scripting.ScriptRuntime;
import hxcore.scripting.ScriptConfig;
import hxcore.scripting.ScriptHost;
import hxcore.scripting.ScriptResolution.OverrideMode;
import hxcore.scripting.Types.HotCompileScope;

class CppiaHcrIntegrationTest extends Test {
	function testHotCompileAndReload() {
		var exportInfoPath = findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var tmpRoot = Sys.getEnv("TMPDIR");
		if (tmpRoot == null || tmpRoot.length == 0) tmpRoot = "/tmp";
		var baseDir = Path.join([tmpRoot, "hxcore_cppia_hcr_test"]);
		var scriptsDir = Path.join([baseDir, "scripts"]);
		var outputDir = Path.join([baseDir, "gen"]);
		FileSystem.createDirectory(baseDir);
		FileSystem.createDirectory(scriptsDir);
		FileSystem.createDirectory(outputDir);

		var externalScriptPath = Path.join([scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, externalScriptSource("v1"));

		var filteredInfoPath = Path.join([scriptsDir, "export_classes.filtered.info"]);
		var filtered = ExportClassesInfoFilter.filterContent(File.getContent(exportInfoPath), [
			"^class scripts\\.Test$"
		]);
		File.saveContent(filteredInfoPath, filtered);

		var haxeArgs = ["-cp", baseDir];
		var result = ScriptCompiler.compileScriptInternal(baseDir, "scripts", "gen", filteredInfoPath, "cppia", haxeArgs, "scripts.Test");
		Assert.equals(0, result);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = scriptsDir;
		cfg.scriptOutputRoot = outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = true;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:String = null;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			marker = cast h.invoke("getMarker");
		});

		Assert.equals("v1", marker);

		// update source to trigger hot compile -> hot reload
		Sys.sleep(1.2);
		File.saveContent(externalScriptPath, externalScriptSource("v2"));

		var cppiaPath = Path.join([outputDir, "scripts", "Test.cppia"]);
		var initialMtime = FileSystem.stat(cppiaPath).mtime.getTime();

		var startCompile = Timer.stamp();
		var compileUpdated = false;
		while (Timer.stamp() - startCompile < 6.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			var mtime = FileSystem.stat(cppiaPath).mtime.getTime();
			if (mtime != initialMtime) {
				compileUpdated = true;
				break;
			}
		}
		Assert.isTrue(compileUpdated);

		var startReload = Timer.stamp();
		var value:String = null;
		while (Timer.stamp() - startReload < 6.0) {
			runtime.tickWatchers();
			var wait2 = @:privateAccess MainLoop.tick();
			if (wait2 > 0) Sys.sleep(Math.min(wait2, 0.05));
			value = cast host.invoke("getMarker");
			if (value == "v2") {
				break;
			}
		}
		Assert.equals("v2", value);

		runtime.dispose();
	}

	function testHotCompileFailureKeepsPreviousScript() {
		var exportInfoPath = findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var tmpRoot = Sys.getEnv("TMPDIR");
		if (tmpRoot == null || tmpRoot.length == 0) tmpRoot = "/tmp";
		var baseDir = Path.join([tmpRoot, "hxcore_cppia_hcr_fail_test"]);
		var scriptsDir = Path.join([baseDir, "scripts"]);
		var outputDir = Path.join([baseDir, "gen"]);
		FileSystem.createDirectory(baseDir);
		FileSystem.createDirectory(scriptsDir);
		FileSystem.createDirectory(outputDir);

		var externalScriptPath = Path.join([scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, externalScriptSource("v1"));

		var filteredInfoPath = Path.join([scriptsDir, "export_classes.filtered.info"]);
		var filtered = ExportClassesInfoFilter.filterContent(File.getContent(exportInfoPath), [
			"^class scripts\\.Test$"
		]);
		File.saveContent(filteredInfoPath, filtered);

		var haxeArgs = ["-cp", baseDir];
		var result = ScriptCompiler.compileScriptInternal(baseDir, "scripts", "gen", filteredInfoPath, "cppia", haxeArgs, "scripts.Test");
		Assert.equals(0, result);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = scriptsDir;
		cfg.scriptOutputRoot = outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = true;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:String = null;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			marker = cast h.invoke("getMarker");
		});

		Assert.equals("v1", marker);

		// write invalid source to force compilation failure
		Sys.sleep(1.2);
		File.saveContent(externalScriptPath, "package scripts;\nclass Test {");

		var start = Timer.stamp();
		var value:String = null;
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			value = cast host.invoke("getMarker");
			if (value != "v1") {
				break;
			}
		}

		Assert.equals("v1", value);

		runtime.dispose();
	}

	function testDependencyChangeTriggersRecompileInSourceRootScope() {
		var exportInfoPath = findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var tmpRoot = Sys.getEnv("TMPDIR");
		if (tmpRoot == null || tmpRoot.length == 0) tmpRoot = "/tmp";
		var baseDir = Path.join([tmpRoot, "hxcore_cppia_hcr_dep_test"]);
		var scriptsDir = Path.join([baseDir, "scripts"]);
		var outputDir = Path.join([baseDir, "gen"]);
		FileSystem.createDirectory(baseDir);
		FileSystem.createDirectory(scriptsDir);
		FileSystem.createDirectory(outputDir);

		var depPath = Path.join([scriptsDir, "Dep.hx"]);
		var testPath = Path.join([scriptsDir, "Test.hx"]);
		File.saveContent(depPath, dependencyScriptSource("v1"));
		File.saveContent(testPath, dependentScriptSource());

		var filteredInfoPath = Path.join([scriptsDir, "export_classes.filtered.info"]);
		var filtered = ExportClassesInfoFilter.filterContent(File.getContent(exportInfoPath), [
			"^class scripts\\.Test$",
			"^class scripts\\.Dep$"
		]);
		File.saveContent(filteredInfoPath, filtered);

		var haxeArgs = ["-cp", baseDir];
		var result = ScriptCompiler.compileScriptInternal(baseDir, "scripts", "gen", filteredInfoPath, "cppia", haxeArgs, "scripts.Test");
		Assert.equals(0, result);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = scriptsDir;
		cfg.scriptOutputRoot = outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = true;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;
		cfg.hotCompileScope = HotCompileScope.SourceRoot;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:String = null;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			marker = cast h.invoke("getMarker");
		});
		Assert.equals("v1", marker);

		// change dependency only
		Sys.sleep(1.2);
		File.saveContent(depPath, dependencyScriptSource("v2"));

		var start = Timer.stamp();
		var value:String = null;
		while (Timer.stamp() - start < 6.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			value = cast host.invoke("getMarker");
			if (value == "v2") break;
		}

		Assert.equals("v2", value);
		runtime.dispose();
	}

	function findExportClassesInfo():String {
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

	function externalScriptSource(marker:String):String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class Test extends Script {",
			"  public function new() { super(); }",
			'  public function getMarker():String return "' + marker + '"; ',
			"}"
		].join("\n");
	}

	function dependencyScriptSource(marker:String):String {
		return [
			"package scripts;",
			"class Dep {",
			'  public static function marker():String return "' + marker + '";',
			"}"
		].join("\n");
	}

	function dependentScriptSource():String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class Test extends Script {",
			"  public function new() { super(); }",
			"  public function getMarker():String return Dep.marker();",
			"}"
		].join("\n");
	}
}
#end
