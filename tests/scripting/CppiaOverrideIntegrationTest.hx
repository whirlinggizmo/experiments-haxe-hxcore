package tests.scripting;

#if cpp
import utest.Test;
import utest.Assert;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import hxcore.util.ExportClassesInfoFilter;
import hxcore.scripting.ScriptCompiler;
import hxcore.scripting.ScriptRuntime;
import hxcore.scripting.ScriptConfig;
import hxcore.scripting.ScriptHost;
import hxcore.scripting.ScriptResolution.OverrideMode;

class CppiaOverrideIntegrationTest extends Test {
	function testExternalOverridesInternal() {
		var exportInfoPath = findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var tmpRoot = Sys.getEnv("TMPDIR");
		if (tmpRoot == null || tmpRoot.length == 0) tmpRoot = "/tmp";
		var baseDir = Path.join([tmpRoot, "hxcore_cppia_test"]);
		var scriptsDir = Path.join([baseDir, "scripts"]);
		var outputDir = Path.join([baseDir, "gen"]);
		FileSystem.createDirectory(baseDir);
		FileSystem.createDirectory(scriptsDir);
		FileSystem.createDirectory(outputDir);

		var externalScriptPath = Path.join([scriptsDir, "Test.hx"]);
		File.saveContent(externalScriptPath, externalScriptSource());

		var filteredInfoPath = Path.join([baseDir, "export_classes.filtered.info"]);
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
		cfg.overrideMode = OverrideMode.ExternalFirst;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:String = null;
		host.loadScript("scripts.Test", _ -> {}, (h) -> {
			marker = cast h.invoke("getMarker");
		});

		Assert.equals("external", marker);
		runtime.dispose();
	}

	function testExternalOnlyMissingScriptReturnsNull() {
		var exportInfoPath = findExportClassesInfo();
		Assert.isTrue(exportInfoPath != null);

		var tmpRoot = Sys.getEnv("TMPDIR");
		if (tmpRoot == null || tmpRoot.length == 0) tmpRoot = "/tmp";
		var baseDir = Path.join([tmpRoot, "hxcore_cppia_override_missing_test"]);
		var scriptsDir = Path.join([baseDir, "scripts"]);
		var outputDir = Path.join([baseDir, "gen"]);
		FileSystem.createDirectory(baseDir);
		FileSystem.createDirectory(scriptsDir);
		FileSystem.createDirectory(outputDir);

		// filter export info but do not create external script
		var filteredInfoPath = Path.join([scriptsDir, "export_classes.filtered.info"]);
		var filtered = ExportClassesInfoFilter.filterContent(File.getContent(exportInfoPath), [
			"^class scripts\\.Test$"
		]);
		File.saveContent(filteredInfoPath, filtered);

		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = scriptsDir;
		cfg.scriptOutputRoot = outputDir;
		cfg.externalEnabled = true;
		cfg.hotCompileEnabled = false;
		cfg.hotReloadEnabled = false;
		cfg.overrideMode = OverrideMode.ExternalOnly;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);

		var marker:Dynamic = "unset";
		host.loadScript("scripts.Test", (created) -> {
			marker = created == null ? null : created.invoke("getMarker");
		}, (loaded) -> {
			marker = loaded == null ? null : loaded.invoke("getMarker");
		});

		Assert.equals(null, marker);
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

	function externalScriptSource():String {
		return [
			"package scripts;",
			"import hxcore.scripting.Script;",
			"class Test extends Script {",
			"  public function new() { super(); }",
			"  public function getMarker():String return \"external\";",
			"}"
		].join("\n");
	}
}
#end
