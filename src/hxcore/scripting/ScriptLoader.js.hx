package hxcore.scripting;

import js.Syntax;
import js.lib.Promise;
import hxcore.logging.Log;
import hxcore.util.TypeUtils;
import hxcore.scripting.Script;
import hxcore.scripting.IScriptLoader;
//
// NOTE:  This code is **very** stale, work has been focused on the cpp version
// TODO:  Update this?
//

class ScriptLoader implements IScriptLoader {
	private static var scriptCache:Map<String, Script> = new Map<String, Script>();
	public static var scriptDirectory:String = "./scripts/";
	public static var scriptSourceDirectory:String = "./src/";

	private static function createInstanceFromModule(m, className) {
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

	private static function _load(scriptName:String, onLoaded:Script->Void):Void {
		// use a cache buster to force the browser to reload
		// This should be possible with vite HMR and accept(), but I can't seem to get it to work

		// the scriptName is the class name of the script, so replace any '.' with '/'
		scriptName = StringTools.replace(scriptName, '.', '/'); // scriptName.replace('.', '/');

		var scriptPath = scriptDirectory + '/' + scriptName + '.js' + "?hotreload-cachebuster=" + Std.string(Date.now().getTime());

		js.Lib.dynamicImport(scriptPath).then(m -> {
			var script:Script = createInstanceFromModule(m, scriptName);
			// ensure it derives from Script
			if (!TypeUtils.isDerivedFrom(Type.getClass(this.script), hxcore.scripting.Script)) {
				Log.error("Script " + scriptName + " does not derive from Script");
				onLoaded(null);
				return;
			}
			// set the script name and directory on the new script
			script.scriptName = scriptName;
			script.scriptDirectory = scriptDirectory;
			onLoaded(script);
		}).catchError(err -> {
			Log.error('Error loading script: ' + err);
			onLoaded(null);
		});
	}

	public static function load(scriptName:String, onLoaded:String->Script->Void):Void {
		if (scriptCache.exists(scriptName)) {
			onLoaded(scriptName, scriptCache.get(scriptName));
			return;
		}

		// TODO: do we want to include the script directory as the package, or add the script directory class path when building?
		// var fullScriptName = scriptDirectory + '.' + scriptName;
		// var fullScriptName = scriptName;

		#if (enable_script_reload)
		_load(scriptName, (script) -> {
			if (script != null) {
				// cache the script instance
				scriptCache.set(scriptName, script);
				onLoaded(scriptName, script);

				// Handle hot module replacement if Vite's HMR is enabled
				var hmr = js.Syntax.code("import.meta.hot");
				if (hmr != null) {
					// We should be able to use the hot module directly, but I can't get it to work
					// Instead, we'll use the ws connection from vite to custom message us when we should reload a script
					hmr.on('hotreload', function(data) {
						// Log.debug("in hot reload:", scriptName, scriptPath, data);
						// var previousScriptInstance = scriptCache.get(scriptName);

						// TODO: This smells recursive.  Break out this function
						_load(scriptName, (changedScript) -> {
							if (changedScript == null) {
								onLoaded(scriptName, null);
								return;
							}
							// cache the updated script instance
							scriptCache.set(scriptName, changedScript);
							onLoaded(scriptName, changedScript);
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
			onLoaded(scriptName, script);
			return;
		} else {
			Log.error("Script " + fullScriptName + " not found.");
			onLoaded(scriptName, null); // Call the callback with the loaded script
			return;
		}
		#end

		return;
	}
}
