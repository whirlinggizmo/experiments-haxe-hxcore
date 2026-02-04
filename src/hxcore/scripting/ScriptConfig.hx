package hxcore.scripting;

import hxcore.scripting.ScriptResolution.OverrideMode;
import hxcore.scripting.Types.HotCompileScope;

class ScriptConfig {
	public var scriptSourceRoot:String;
	public var scriptOutputRoot:String;
	public var generatedNamespace:String;
	public var overrideMode:OverrideMode;
	public var externalEnabled:Bool;
	public var hotReloadEnabled:Bool;
	public var hotCompileEnabled:Bool;
	public var hotCompileScope:HotCompileScope;
	public var debounceMs:Int;

	public function new() {
		scriptSourceRoot = "scripts";
		scriptOutputRoot = "gen";
		generatedNamespace = "gen";
		overrideMode = OverrideMode.ExternalFirst;
		externalEnabled = false;
		hotReloadEnabled = false;
		hotCompileEnabled = false;
		hotCompileScope = HotCompileScope.ScriptOnly;
		debounceMs = 150;
	}

	public function withSourceRoot(path:String):ScriptConfig {
		scriptSourceRoot = path;
		return this;
	}

	public function withOutputRoot(path:String):ScriptConfig {
		scriptOutputRoot = path;
		return this;
	}

	public function withGeneratedNamespace(namespace:String):ScriptConfig {
		generatedNamespace = namespace;
		return this;
	}

	public function withOverrideMode(mode:OverrideMode):ScriptConfig {
		overrideMode = mode;
		return this;
	}

	public function enableExternal(enable:Bool = true):ScriptConfig {
		externalEnabled = enable;
		return this;
	}

	public function enableHotReload(enable:Bool = true):ScriptConfig {
		hotReloadEnabled = enable;
		return this;
	}

	public function enableHotCompile(enable:Bool = true):ScriptConfig {
		hotCompileEnabled = enable;
		return this;
	}

	public function withHotCompileScope(scope:HotCompileScope):ScriptConfig {
		hotCompileScope = scope;
		return this;
	}

	public function withDebounceMs(ms:Int):ScriptConfig {
		debounceMs = ms;
		return this;
	}

	public function normalizePaths():Void {
		if (scriptSourceRoot != null && scriptSourceRoot.length > 0) {
			scriptSourceRoot = hxcore.util.PathUtils.normalizePath(scriptSourceRoot);
		}
		if (scriptOutputRoot != null && scriptOutputRoot.length > 0) {
			scriptOutputRoot = hxcore.util.PathUtils.normalizePath(scriptOutputRoot);
		}
	}
}
