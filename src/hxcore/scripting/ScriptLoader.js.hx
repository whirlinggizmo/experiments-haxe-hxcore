package hxcore.scripting;

import js.Syntax;
import js.lib.Promise;
import hxcore.logging.Log;
import hxcore.util.TypeUtils;
import hxcore.scripting.Script;
import hxcore.scripting.IScriptLoader;
import hxcore.scripting.ScriptResolution;
import hxcore.scripting.Types.HotCompileScope;
//
// NOTE:  This code is **very** stale, work has been focused on the cpp version
// TODO:  Update this?
//

class ScriptLoader implements IScriptLoader {
	private var scriptCache:Map<String, Script> = new Map<String, Script>();
	public var scriptDirectory:String = "./scripts/";
	public var scriptSourceDirectory:String = "./src/";
	private var externalScriptsEnabled:Bool = false;
	private var hotReloadEnabled:Bool = false;
	private var hotCompileEnabled:Bool = false;
	private var hotCompileScope:HotCompileScope = HotCompileScope.ScriptOnly;

	public function new() {}

	public function setScriptDirectory(dir:String):Void {
		scriptDirectory = dir;
	}

	public function setScriptSourceDirectory(dir:String):Void {
		scriptSourceDirectory = dir;
	}

	public function setOverrideMode(mode:ScriptResolution.OverrideMode):Void {}

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

	private function createInstanceFromModule(m, className) {
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

	private function _load(scriptName:String, onLoaded:ScriptInfo->Void):Void {
		// use a cache buster to force the browser to reload
		// This should be possible with vite HMR and accept(), but I can't seem to get it to work

		// the scriptName is the class name of the script, so replace any '.' with '/'
		scriptName = StringTools.replace(scriptName, '.', '/'); // scriptName.replace('.', '/');

		var scriptPath = scriptDirectory + '/' + scriptName + '.js' + "?hotreload-cachebuster=" + Std.string(Date.now().getTime());

			js.Lib.dynamicImport(scriptPath).then(m -> {
				var script:Script = createInstanceFromModule(m, scriptName);
				// ensure it derives from Script
				if (!TypeUtils.isDerivedFrom(Type.getClass(script), hxcore.scripting.Script)) {
					Log.error("Script " + scriptName + " does not derive from Script");
					onLoaded(null);
					return;
				}
				// set the script name and directory on the new script
				script.scriptName = scriptName;
				script.scriptDirectory = scriptDirectory;
				var scriptInfo = {
					className: scriptName,
					script: script,
					loadedCallback: null,
					isExternal: true,
					sourcePath: scriptPath
				};
				onLoaded(scriptInfo);
		}).catchError(err -> {
			Log.error('Error loading script: ' + err);
			onLoaded(null);
		});
	}

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		if (scriptCache.exists(scriptName)) {
			var cached = scriptCache.get(scriptName);
			var cachedInfo = {
				className: scriptName,
				script: cached,
				loadedCallback: onLoaded,
				isExternal: true,
				sourcePath: scriptDirectory + '/' + scriptName + '.js'
			};
			onLoaded(scriptName, cachedInfo);
			return;
		}

		// TODO: do we want to include the script directory as the package, or add the script directory class path when building?
		// var fullScriptName = scriptDirectory + '.' + scriptName;
		// var fullScriptName = scriptName;

		#if (enable_script_reload)
		_load(scriptName, (scriptInfo) -> {
			if (scriptInfo != null && scriptInfo.script != null) {
				// cache the script instance
				scriptCache.set(scriptName, scriptInfo.script);
				onLoaded(scriptName, scriptInfo);

				// Handle hot module replacement if Vite's HMR is enabled
				var hmr = js.Syntax.code("import.meta.hot");
				if (hmr != null) {
					// We should be able to use the hot module directly, but I can't get it to work
					// Instead, we'll use the ws connection from vite to custom message us when we should reload a script
					hmr.on('hotreload', function(data) {
						// Log.debug("in hot reload:", scriptName, scriptPath, data);
						// var previousScriptInstance = scriptCache.get(scriptName);

						// TODO: This smells recursive.  Break out this function
						_load(scriptName, (changedScriptInfo) -> {
							if (changedScriptInfo == null || changedScriptInfo.script == null) {
								onLoaded(scriptName, null);
								return;
							}
							// cache the updated script instance
							scriptCache.set(scriptName, changedScriptInfo.script);
							onLoaded(scriptName, changedScriptInfo);
						});
					});
				}
				// end hmr
			} else {
				Log.error('Error loading script: ' + fullScriptName);
				onLoaded(scriptName, null);
			}
		});
		#else
		var scriptClass = Type.resolveClass(fullScriptName);
		if (scriptClass != null) {
			// ensure it derives from Script
			if (!TypeUtils.isDerivedFrom(scriptClass, hxcore.scripting.Script)) {
				Log.error("Script " + scriptName + " does not derive from hxcore.scripting.Script");
				if (onLoaded != null) {
					onLoaded(scriptName, null); // Call the callback with the loaded script
				}
				return;
			}

			var script = Type.createInstance(scriptClass, []);
			if (script == null) {
				Log.error('Error creating script instance: ' + fullScriptName);
				onLoaded(scriptName, null);
				return;
			}

			scriptCache.set(scriptName, script);
			var scriptInfo = {
				className: scriptName,
				script: script,
				loadedCallback: onLoaded,
				isExternal: false,
				sourcePath: scriptDirectory + '/' + scriptName + '.js'
			};
			onLoaded(scriptName, scriptInfo);
			return;
		} else {
			Log.error("Script " + fullScriptName + " not found.");
			onLoaded(scriptName, null); // Call the callback with the loaded script
			return;
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

	public function dispose():Void {
		scriptCache.clear();
	}
}
