package tests.scripting;

#if cpp
import utest.Test;
import utest.Assert;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.Timer;
import haxe.MainLoop;
import hxcore.scripting.ScriptRuntime;
import hxcore.scripting.ScriptConfig;
import hxcore.scripting.ScriptConfig.HotCompileScope;
import hxcore.scripting.ScriptHost;
import hxcore.scripting.ScriptResolution.OverrideMode;

/**
 * Tests for hot-compile and reload functionality.
 */
class CppiaHcrCompileTest extends Test {
	function testHotCompileAndReload() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_hcr_test");
		var externalScriptPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v1"));

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$"
		]);
		var result = CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");
		Assert.equals(0, result);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = dirs.scriptsDir;
		cfg.scriptOutputRoot = dirs.outputDir;
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

		Sys.sleep(1.2);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v2"));

		var cppiaPath = Path.join([dirs.outputDir, "scripts", "Test.cppia"]);
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
			if (value == "v2") break;
		}
		Assert.equals("v2", value);

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	function testHotCompileFailureKeepsPreviousScript() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_hcr_fail_test");
		var externalScriptPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v1"));

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$"
		]);
		var result = CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");
		Assert.equals(0, result);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = dirs.scriptsDir;
		cfg.scriptOutputRoot = dirs.outputDir;
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

		Sys.sleep(1.2);
		File.saveContent(externalScriptPath, "package scripts;\nclass Test {");

		var start = Timer.stamp();
		var value:String = null;
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			value = cast host.invoke("getMarker");
			if (value != "v1") break;
		}
		Assert.equals("v1", value);

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	function testDependencyChangeTriggersRecompileInSourceRootScope() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_hcr_dep_test");
		var depPath = Path.join([dirs.scriptsDir, "Dep.hx"]);
		var testPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(depPath, CppiaHcrTestBase.dependencyScriptSource("v1"));
		File.saveContent(testPath, CppiaHcrTestBase.dependentScriptSource());

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$",
			"^class scripts\\.Dep$"
		]);
		var result = CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");
		Assert.equals(0, result);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = dirs.scriptsDir;
		cfg.scriptOutputRoot = dirs.outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = true;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;
		cfg.hotCompileScope = HotCompileScope.ScriptDirectory;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:String = null;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			marker = cast h.invoke("getMarker");
		});
		Assert.equals("v1", marker);

		Sys.sleep(1.2);
		File.saveContent(depPath, CppiaHcrTestBase.dependencyScriptSource("v2"));

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
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}
}
#end
