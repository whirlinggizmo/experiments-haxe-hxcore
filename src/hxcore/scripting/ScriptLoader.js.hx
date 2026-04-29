package hxcore.scripting;

import js.Syntax;
import js.lib.Promise;
import hxcore.logging.Log;
import hxcore.util.TypeUtils;
import hxcore.scripting.Script;
import hxcore.scripting.IScriptLoader;
import hxcore.scripting.IScriptLoader.ScriptInfo;
import hxcore.scripting.ScriptConfig.HotCompileScope;
import hxcore.scripting.ScriptResolution;
//
// NOTE:  This code is **very** stale, work has been focused on the cpp version
// TODO:  Update this?
//

class ScriptLoader implements IScriptLoader {
	private var scriptCache:Map<String, ScriptInfo> = new Map<String, ScriptInfo>();
	public var scriptDirectory:String = "./scripts/";
	public var scriptSourceDirectory:String = "./src/";
	private var externalScriptsEnabled:Bool = false;
	private var hotReloadEnabled:Bool = false;
	private var hotCompileEnabled:Bool = false;
	private var hotCompileScope:HotCompileScope = HotCompileScope.ScriptOnly;
	private var overrideMode:ScriptResolution.OverrideMode = ScriptResolution.OverrideMode.ExternalFirst;

	public function new() {}

	public function setScriptDirectory(dir:String):Void {
		scriptDirectory = hxcore.util.PathUtils.normalizePath(dir);
	}

	public function setScriptSourceDirectory(dir:String):Void {
		scriptSourceDirectory = hxcore.util.PathUtils.normalizePath(dir);
	}

	public function setOverrideMode(mode:ScriptResolution.OverrideMode):Void {
		overrideMode = mode;
	}

	public function setChangeDebounceMs(ms:Int):Void {}

	public function setExternalEnabled(enable:Bool, ?scriptDirectory:String):Void {
		externalScriptsEnabled = enable;
		if (scriptDirectory != null) this.scriptDirectory = scriptDirectory;
	}

	public function setHotReloadEnabled(enable:Bool):Void {
		hotReloadEnabled = enable;
	}

	public function setHotCompileEnabled(enable:Bool, ?scriptSourceDirectory:String):Void {
		hotCompileEnabled = enable;
		if (scriptSourceDirectory != null) this.scriptSourceDirectory = scriptSourceDirectory;
	}

	public function setHotCompileScope(scope:HotCompileScope):Void {
		hotCompileScope = scope;
	}

	public function tickWatchers():Void {
		// no-op on JS target
	}

	private function createInstanceFromModule(m, className:String):Script {
		var instance = Syntax.code("(() => {
			if (m.default != null) {
				//console.log('m.default: ' + m.default);
				try { return new m.default() } catch (e) { console.error(e); } //return new m.default();
			}
			if (m[className]) {
				//console.log('m[className]: ' + m[className]);
				try { return new m[className]() } catch (e) { console.error(e); } //return new m[className]();
			}
			if (window?.[className]) {
				//console.log('window[className]: ' + window[className]);
				try { return new window[className]() } catch (e) { console.error(e); } //return new window[className]();
			}
			
			console.error(`Unable to instance class from module: ${className}`);
			return null;
		})()");

		if (instance == null) {
			Log.error('Error creating script instance from module script: $className');
		}

		return instance;
	}

	private function createScriptInfo(scriptName:String, script:Script, isExternal:Bool, sourcePath:String, ?loadedCallback:String->ScriptInfo->Void):ScriptInfo {
		script.scriptName = scriptName;
		script.scriptDirectory = sourcePath;
		return {
			className: scriptName,
			script: script,
			loadedCallback: loadedCallback,
			isExternal: isExternal,
			sourcePath: sourcePath
		};
	}

	private function createInternalScriptInfo(scriptName:String, ?loadedCallback:String->ScriptInfo->Void):ScriptInfo {
		var scriptClass = Type.resolveClass(scriptName);
		if (scriptClass == null) {
			Log.error("Script " + scriptName + " not found.");
			return null;
		}
		if (!TypeUtils.isDerivedFrom(scriptClass, hxcore.scripting.Script)) {
			Log.error("Script " + scriptName + " does not derive from hxcore.scripting.Script");
			return null;
		}
		var script = Type.createInstance(scriptClass, []);
		if (script == null) {
			Log.error('Error creating script instance: ' + scriptName);
			return null;
		}
		return createScriptInfo(scriptName, cast script, false, scriptName, loadedCallback);
	}

	private function loadExternalScript(scriptName:String, onLoaded:ScriptInfo->Void):Void {
		// use a cache buster to force the browser to reload
		// This should be possible with vite HMR and accept(), but I can't seem to get it to work

		var relativeScriptPath = ScriptPathResolver.compiledScriptRelativePath(scriptName, "js");
		var scriptPath = scriptDirectory + '/' + relativeScriptPath + "?hotreload-cachebuster=" + Std.string(Date.now().getTime());

		js.Lib.dynamicImport(scriptPath).then(m -> {
				var script:Script = createInstanceFromModule(m, scriptName.split(".").pop());
				// ensure it derives from Script
				if (script == null || !TypeUtils.isDerivedFrom(Type.getClass(script), hxcore.scripting.Script)) {
					Log.error("Script " + scriptName + " does not derive from Script");
					onLoaded(null);
					return;
				}
				onLoaded(createScriptInfo(scriptName, script, true, scriptPath));
		}).catchError(err -> {
			Log.error('Error loading script: ' + err);
			onLoaded(null);
		});
	}

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		if (scriptCache.exists(scriptName)) {
			var cachedInfo = scriptCache.get(scriptName);
			cachedInfo.loadedCallback = onLoaded;
			onLoaded(scriptName, cachedInfo);
			return;
		}

		var internalInfo = createInternalScriptInfo(scriptName, onLoaded);
		var hasInternal = internalInfo != null;
		var hasExternal = externalScriptsEnabled;
		var sourceChoice = ScriptResolution.chooseSourceWithExternalEnabled(hasExternal, hasInternal, externalScriptsEnabled, overrideMode);

		#if (enable_script_reload)
		function finalizeLoadedInfo(scriptInfo:ScriptInfo):Void {
			if (scriptInfo == null || scriptInfo.script == null) {
				onLoaded(scriptName, null);
				return;
			}
			scriptInfo.loadedCallback = onLoaded;
			scriptCache.set(scriptName, scriptInfo);
			onLoaded(scriptName, scriptInfo);

			if (scriptInfo.isExternal == true && hotReloadEnabled) {
				var hmr = js.Syntax.code("import.meta.hot");
				if (hmr != null) {
					hmr.on('hotreload', function(data) {
						loadExternalScript(scriptName, (changedScriptInfo) -> {
							if (changedScriptInfo == null || changedScriptInfo.script == null) {
								onLoaded(scriptName, null);
								return;
							}
							changedScriptInfo.loadedCallback = onLoaded;
							scriptCache.set(scriptName, changedScriptInfo);
							onLoaded(scriptName, changedScriptInfo);
						});
					});
				}
			}
		}

		switch (sourceChoice) {
			case ScriptResolution.ScriptSource.External:
				loadExternalScript(scriptName, (scriptInfo) -> {
					if (scriptInfo == null && overrideMode == ScriptResolution.OverrideMode.ExternalFirst && hasInternal) {
						finalizeLoadedInfo(internalInfo);
						return;
					}
					finalizeLoadedInfo(scriptInfo);
				});
			case ScriptResolution.ScriptSource.Internal:
				finalizeLoadedInfo(internalInfo);
			case ScriptResolution.ScriptSource.None:
				onLoaded(scriptName, null);
		}
		#else
		switch (sourceChoice) {
			case ScriptResolution.ScriptSource.External:
				Log.warn("External JS script loading requires enable_script_reload.");
				if (overrideMode == ScriptResolution.OverrideMode.ExternalFirst && hasInternal) {
					scriptCache.set(scriptName, internalInfo);
					onLoaded(scriptName, internalInfo);
				} else {
					onLoaded(scriptName, null);
				}
			case ScriptResolution.ScriptSource.Internal:
				scriptCache.set(scriptName, internalInfo);
				onLoaded(scriptName, internalInfo);
			case ScriptResolution.ScriptSource.None:
				onLoaded(scriptName, null);
		}
		#end

		return;
	}

	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		if (scriptCache.exists(scriptName)) {
			scriptCache.remove(scriptName);
		}
		load(scriptName, onLoaded);
	}

	public function unload(scriptName:String):Void {
		if (scriptCache.exists(scriptName)) {
			scriptCache.remove(scriptName);
		}
	}

	public function isLoaded(scriptName:String):Bool {
		return scriptCache.exists(scriptName);
	}

	public function dispose():Void {
		scriptCache.clear();
	}
}
