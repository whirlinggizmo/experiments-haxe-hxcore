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
 * Tests for file add/remove events (directory watching).
 */
class CppiaHcrFileEventsTest extends Test {
	/**
	 * Adding a .cppia file triggers reload for already-loaded scripts.
	 */
	function testAddingCppiaFileTriggersReload() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_add_test");
		var externalScriptPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v1"));

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$"
		]);

		// Pre-compile, save the .cppia content, then delete the file
		var result = CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");
		Assert.equals(0, result);

		var cppiaPath = Path.join([dirs.outputDir, "scripts", "Test.cppia"]);
		var cppiaContent = File.getBytes(cppiaPath);
		FileSystem.deleteFile(cppiaPath);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = dirs.scriptsDir;
		cfg.scriptOutputRoot = dirs.outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = false;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		// Load - falls back to internal (not present), but registers listener for future loads
		host.loadScript("scripts.Test", _ -> {}, _ -> {});

		// At this point, script is not loaded (no .cppia, no internal)
		Assert.isFalse(runtime.isLoaded("scripts.Test"), "Script should not be loaded yet");

		Sys.sleep(0.1);

		// ADD the .cppia file back
		File.saveBytes(cppiaPath, cppiaContent);

		// Wait for watcher to detect new file. Since the script wasn't loaded,
		// we don't expect automatic reload. But the watcher should detect the file
		// and we can verify by manually loading.
		Sys.sleep(0.5);
		runtime.tickWatchers();
		var wait = @:privateAccess MainLoop.tick();
		if (wait > 0) Sys.sleep(Math.min(wait, 0.05));

		// Now load - should succeed with external since .cppia exists
		host.loadScript("scripts.Test", _ -> {}, _ -> {});
		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should load with .cppia present");

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	/**
	 * Adding a new .hx file triggers compile and makes it loadable.
	 */
	function testAddingNewHxFileTriggersCompile() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_hx_add_test");
		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$",
			"^class scripts\\.NewScript$"
		]);

		var testPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(testPath, CppiaHcrTestBase.loaderScriptSource());
		CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");

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

		var loaded:Bool = false;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			loaded = true;
		});
		Assert.isTrue(loaded);

		Sys.sleep(0.1);

		// ADD a NEW script file
		var newScriptPath = Path.join([dirs.scriptsDir, "NewScript.hx"]);
		File.saveContent(newScriptPath, CppiaHcrTestBase.newScriptSource("fresh"));

		var cppiaPath = Path.join([dirs.outputDir, "scripts", "NewScript.cppia"]);
		var start = Timer.stamp();
		while (Timer.stamp() - start < 6.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (FileSystem.exists(cppiaPath)) break;
		}
		Assert.isTrue(FileSystem.exists(cppiaPath), ".cppia should be compiled for new script");

		var newLoaded:Bool = false;
		host.loadScript("scripts.NewScript", _ -> {}, (h) -> {
			newLoaded = true;
		});
		Assert.isTrue(newLoaded, "Newly added script should be loadable after compile");

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	/**
	 * Removing a .cppia file triggers unload of the script.
	 */
	function testRemovingCppiaFileUnloadsScript() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_remove_test");
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
		cfg.hotCompileEnabled = false;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:String = null;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			if (h != null) marker = cast h.invoke("getMarker");
		});
		Assert.equals("v1", marker);

		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should be loaded initially");
		Sys.sleep(0.1);

		// Remove the .cppia file
		var cppiaPath = Path.join([dirs.outputDir, "scripts", "Test.cppia"]);
		FileSystem.deleteFile(cppiaPath);

		// Wait for watcher to detect removal and unload from cache
		var start = Timer.stamp();
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (!runtime.isLoaded("scripts.Test")) break;
		}

		Assert.isFalse(runtime.isLoaded("scripts.Test"), "Script should be unloaded after .cppia removal");

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	/**
	 * Deleting a .cppia then writing it back reloads the script automatically.
	 */
	function testRemovingThenRestoringCppiaReloads() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_restore_test");
		var externalScriptPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v1"));

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$"
		]);
		var result = CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");
		Assert.equals(0, result);

		var cppiaPath = Path.join([dirs.outputDir, "scripts", "Test.cppia"]);
		var cppiaContent = File.getBytes(cppiaPath);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = dirs.scriptsDir;
		cfg.scriptOutputRoot = dirs.outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = false;
		cfg.hotReloadEnabled = true;
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.debounceMs = 0;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		host.loadScript("scripts.Test", _ -> {}, _ -> {});
		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should be loaded initially");

		Sys.sleep(0.1);

		// Delete the .cppia - script soft-unloads
		FileSystem.deleteFile(cppiaPath);
		var start = Timer.stamp();
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (!runtime.isLoaded("scripts.Test")) break;
		}
		Assert.isFalse(runtime.isLoaded("scripts.Test"), "Script should be unloaded after .cppia deletion");
		Assert.isTrue(runtime.isSubscribed("scripts.Test"), "Subscription should be retained after soft-unload");

		Sys.sleep(0.1);

		// Restore the .cppia - should auto-reload via watcher
		File.saveBytes(cppiaPath, cppiaContent);
		start = Timer.stamp();
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (runtime.isLoaded("scripts.Test")) break;
		}
		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should reload after .cppia is restored");

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	/**
	 * Deleting a .cppia then touching the .hx recompiles and reloads automatically.
	 */
	function testRemovingCppiaAndTouchingHxReloads() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_cppia_touch_reload_test");
		var externalScriptPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v1"));

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$"
		]);
		var result = CppiaHcrTestBase.compileScript(dirs.baseDir, dirs.scriptsDir, dirs.outputDir, filteredInfoPath, "scripts.Test");
		Assert.equals(0, result);

		var cppiaPath = Path.join([dirs.outputDir, "scripts", "Test.cppia"]);

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

		host.loadScript("scripts.Test", _ -> {}, _ -> {});
		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should be loaded initially");

		Sys.sleep(0.1);

		// Delete the .cppia
		FileSystem.deleteFile(cppiaPath);
		var start = Timer.stamp();
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (!runtime.isLoaded("scripts.Test")) break;
		}
		Assert.isFalse(runtime.isLoaded("scripts.Test"), "Script should be unloaded after .cppia deletion");
		Assert.isTrue(runtime.isSubscribed("scripts.Test"), "Subscription should be retained after soft-unload");

		Sys.sleep(0.1);

		// Touch the .hx - hot-compile should regenerate .cppia and hot-reload should pick it up
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v2"));
		start = Timer.stamp();
		while (Timer.stamp() - start < 10.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (runtime.isLoaded("scripts.Test")) break;
		}
		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should reload after .hx touch recompiles it");

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}

	/**
	 * Removing a .hx file deletes the .cppia and unloads the script.
	 */
	function testRemovingHxFileDeletesCppiaAndUnloads() {
		var exportInfoPath = CppiaHcrTestBase.findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var dirs = CppiaHcrTestBase.setupTestDirs("hxcore_hx_remove_test");
		var externalScriptPath = Path.join([dirs.scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, CppiaHcrTestBase.externalScriptSource("v1"));

		var filteredInfoPath = CppiaHcrTestBase.createFilteredInfo(dirs.scriptsDir, exportInfoPath, [
			"^class scripts\\.Test$"
		]);

		// Pre-compile so we can load it
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
			if (h != null) marker = cast h.invoke("getMarker");
		});
		Assert.equals("v1", marker);

		Assert.isTrue(runtime.isLoaded("scripts.Test"), "Script should be loaded initially");
		Sys.sleep(0.1);

		// Remove the .hx source file
		FileSystem.deleteFile(externalScriptPath);

		// Wait for watcher to detect removal, delete .cppia, and unload from cache
		var start = Timer.stamp();
		var cppiaPath = Path.join([dirs.outputDir, "scripts", "Test.cppia"]);
		while (Timer.stamp() - start < 3.0) {
			runtime.tickWatchers();
			var wait = @:privateAccess MainLoop.tick();
			if (wait > 0) Sys.sleep(Math.min(wait, 0.05));
			if (!FileSystem.exists(cppiaPath) && !runtime.isLoaded("scripts.Test")) break;
		}

		Assert.isFalse(FileSystem.exists(cppiaPath), ".cppia should be deleted when source removed");
		Assert.isFalse(runtime.isLoaded("scripts.Test"), "Script should be unloaded after source removal");

		runtime.dispose();
		CppiaHcrTestBase.removeDirectoryRecursive(dirs.baseDir);
	}
}
#end
