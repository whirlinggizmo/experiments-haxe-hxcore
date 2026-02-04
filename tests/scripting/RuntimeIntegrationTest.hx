package tests.scripting;

import utest.Test;
import utest.Assert;
import hxcore.scripting.ScriptHost;
import hxcore.scripting.ScriptRuntime;
import hxcore.scripting.IScriptLoader;
import hxcore.scripting.Types.ScriptInfo;
import hxcore.scripting.Types.HotCompileScope;

private class TestLoader implements IScriptLoader {
	public function new() {}
	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		var cls = Type.resolveClass(scriptName);
		if (cls == null) {
			onLoaded(scriptName, null);
			return;
		}
		var instance = Type.createInstance(cls, []);
		var info:ScriptInfo = {
			className: scriptName,
			script: cast instance,
			loadedCallback: onLoaded,
			isExternal: false,
			sourcePath: scriptName
		};
		onLoaded(scriptName, info);
	}
	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		load(scriptName, onLoaded);
	}
	public function unload(scriptName:String):Void {}
	public function dispose():Void {}
	public function setScriptDirectory(dir:String):Void {}
	public function setScriptSourceDirectory(dir:String):Void {}
	public function setOverrideMode(mode:hxcore.scripting.ScriptResolution.OverrideMode):Void {}
	public function setChangeDebounceMs(ms:Int):Void {}
	public function setExternalEnabled(enable:Bool, ?scriptDirectory:String):Void {}
	public function setHotReloadEnabled(enable:Bool):Void {}
	public function setHotCompileEnabled(enable:Bool, ?scriptSourceDirectory:String):Void {}
	public function setHotCompileScope(scope:HotCompileScope):Void {}
	public function tickWatchers():Void {}
}

class RuntimeIntegrationTest extends Test {
	function setup() {
		FakeScript.loadCount = 0;
		FakeScript.updateCount = 0;
		FakeScriptTwo.loadCount = 0;
		FakeScriptTwo.updateCount = 0;
	}

	function testScriptLoaderLoadsInternalScript() {
		var runtime = new ScriptRuntime(null, new TestLoader());
		runtime.load("tests.scripting.FakeScript", (name, info) -> {
			Assert.equals("tests.scripting.FakeScript", name);
			Assert.isTrue(info != null);
			Assert.isTrue(info.script != null);
			Assert.equals("tests.scripting.FakeScript", info.className);
		});
	}

	function testScriptHostLifecycle() {
		var runtime = new ScriptRuntime(null, new TestLoader());
		var host = new ScriptHost(runtime);
		host.loadScript("tests.scripting.FakeScript", _ -> {}, _ -> {});
		Assert.equals(1, FakeScript.loadCount);
		host.update(16.0);
		Assert.equals(1, FakeScript.updateCount);
		host.dispose();
	}

	function testScriptRuntimeDelegatesLoad() {
		var runtime = new ScriptRuntime(null, new TestLoader());
		runtime.load("tests.scripting.FakeScript", (name, info) -> {
			Assert.equals("tests.scripting.FakeScript", name);
			Assert.isTrue(info != null);
		});
	}

	function testMultipleScriptsLoadIndependently() {
		var runtime = new ScriptRuntime(null, new TestLoader());
		var hostA = new ScriptHost(runtime);
		var hostB = new ScriptHost(runtime);
		hostA.loadScript("tests.scripting.FakeScript", _ -> {}, _ -> {});
		hostB.loadScript("tests.scripting.FakeScriptTwo", _ -> {}, _ -> {});
		Assert.equals(1, FakeScript.loadCount);
		Assert.equals(1, FakeScriptTwo.loadCount);
		hostA.update(16.0);
		hostB.update(16.0);
		Assert.equals(1, FakeScript.updateCount);
		Assert.equals(1, FakeScriptTwo.updateCount);
		hostA.dispose();
		hostB.dispose();
	}
}
