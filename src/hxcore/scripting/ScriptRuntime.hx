package hxcore.scripting;

import hxcore.logging.Log;
#if (cpp || scriptable)
import hxcore.scripting.ScriptCompiler;
#end
import hxcore.scripting.Types.HotCompileScope;
import hxcore.scripting.Types.ScriptInfo;

class ScriptRuntime {
	public var config:ScriptConfig;
	private var loader:IScriptLoader;
	private static var defaultRuntime:ScriptRuntime = null;

	public function new(?config:ScriptConfig, ?loader:IScriptLoader) {
		this.config = config != null ? config : new ScriptConfig();
		this.loader = loader != null ? loader : new ScriptLoader();
		applyConfig();
	}

	public static function getDefault():ScriptRuntime {
		if (defaultRuntime == null) {
			defaultRuntime = new ScriptRuntime();
		}
		return defaultRuntime;
	}

	public function setConfig(config:ScriptConfig):ScriptRuntime {
		this.config = config != null ? config : new ScriptConfig();
		applyConfig();
		return this;
	}

	public function applyConfig():Void {
		config.normalizePaths();
		#if (cpp || scriptable)
		ScriptCompiler.setGeneratedScriptNamespace(config.generatedNamespace);
		#end
		loader.setScriptDirectory(config.scriptOutputRoot);
		loader.setScriptSourceDirectory(config.scriptSourceRoot);
		loader.setOverrideMode(config.overrideMode);
		loader.setChangeDebounceMs(config.debounceMs);
		loader.setExternalEnabled(config.externalEnabled, config.scriptOutputRoot);
		loader.setHotReloadEnabled(config.hotReloadEnabled);
		loader.setHotCompileEnabled(config.hotCompileEnabled, config.scriptSourceRoot);
		loader.setHotCompileScope(config.hotCompileScope);
	}

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		Log.debug('ScriptRuntime.load: ${scriptName}');
		loader.load(scriptName, onLoaded);
	}

	public function reload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		Log.debug('ScriptRuntime.reload: ${scriptName}');
		loader.forceReload(scriptName, onLoaded);
	}

	public function unload(scriptName:String):Void {
		Log.debug('ScriptRuntime.unload: ${scriptName}');
		loader.unload(scriptName);
	}

	public function dispose():Void {
		loader.dispose();
	}

	/**
	 * Force watcher scans when supported (primarily for deterministic tests).
	 */
	public function tickWatchers():Void {
		loader.tickWatchers();
	}
}
