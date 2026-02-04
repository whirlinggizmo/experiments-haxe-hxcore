package tests.scripting;

import utest.Test;
import utest.Assert;
import hxcore.scripting.IScriptLoader;
import hxcore.scripting.ScriptConfig;
import hxcore.scripting.ScriptRuntime;
import hxcore.scripting.ScriptResolution;
import hxcore.scripting.ScriptResolution.OverrideMode;
import hxcore.scripting.ScriptResolution.ScriptSource;
import hxcore.scripting.Types.ScriptInfo;
import hxcore.scripting.Types.HotCompileScope;

private class FakeLoader implements IScriptLoader {
	public var scriptDir:String;
	public var scriptSourceDir:String;
	public var overrideMode:OverrideMode;
	public var debounceMs:Int;
	public var externalEnabled:Bool;
	public var hotReloadEnabled:Bool;
	public var hotCompileEnabled:Bool;
	public var hotCompileScope:HotCompileScope;

	public function new() {}

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {}
	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {}
	public function unload(scriptName:String):Void {}
	public function dispose():Void {}

	public function setScriptDirectory(dir:String):Void scriptDir = dir;
	public function setScriptSourceDirectory(dir:String):Void scriptSourceDir = dir;
	public function setOverrideMode(mode:OverrideMode):Void overrideMode = mode;
	public function setChangeDebounceMs(ms:Int):Void debounceMs = ms;
	public function setExternalEnabled(enable:Bool, ?scriptDirectory:String):Void externalEnabled = enable;
	public function setHotReloadEnabled(enable:Bool):Void hotReloadEnabled = enable;
	public function setHotCompileEnabled(enable:Bool, ?scriptSourceDirectory:String):Void hotCompileEnabled = enable;
	public function setHotCompileScope(scope:HotCompileScope):Void hotCompileScope = scope;
	public function tickWatchers():Void {}
}

class RuntimeConfigIntegrationTest extends Test {
	function testRuntimeAppliesConfigToLoader() {
		var cfg = new ScriptConfig();
		cfg.scriptSourceRoot = "scripts";
		cfg.scriptOutputRoot = "gen";
		cfg.overrideMode = OverrideMode.ExternalOnly;
		cfg.debounceMs = 250;
		cfg.externalEnabled = true;
		cfg.hotReloadEnabled = true;
		cfg.hotCompileEnabled = true;
		cfg.hotCompileScope = HotCompileScope.SourceRoot;

		var loader = new FakeLoader();
		var runtime = new ScriptRuntime(cfg, loader);

		Assert.equals("gen", loader.scriptDir);
		Assert.equals("scripts", loader.scriptSourceDir);
		Assert.equals(OverrideMode.ExternalOnly, loader.overrideMode);
		Assert.equals(250, loader.debounceMs);
		Assert.equals(true, loader.externalEnabled);
		Assert.equals(true, loader.hotReloadEnabled);
		Assert.equals(true, loader.hotCompileEnabled);
		Assert.equals(HotCompileScope.SourceRoot, loader.hotCompileScope);
	}

	function testOverrideResolutionWithExternalToggle() {
		var cfg = new ScriptConfig();
		cfg.overrideMode = OverrideMode.ExternalFirst;
		cfg.externalEnabled = false;

		var source = ScriptResolution.chooseSourceWithExternalEnabled(true, true, cfg.externalEnabled, cfg.overrideMode);
		Assert.equals(ScriptSource.Internal, source);
	}
}
