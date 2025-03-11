package core.scripting;

import js.Syntax;
import js.lib.Promise;
import core.logging.Log;

class ScriptLoader {
	private static var scriptCache:Map<String, Script> = new Map<String, Script>();
	public static var scriptDirectory:String = './scripts/';

	private static function createInstanceFromModule(m, className) {
		Syntax.code("
			if (m.default != null) {
				return new m.default();
			}
			if (m[className]) {
				return new m[className]();
			}
			if (window?.[className]) {
				return new window[className]();
			}
			return m;
		");

		Log.debug('Error creating script instance from module script: $className');
		return null;
	}

	private static function _load(scriptName:String, onLoaded:Script->Void):Void {
		// use a cache buster to force the browser to reload
		// This should be possible with vite HMR and accept(), but I can't seem to get it to work

		/*
			var scriptPath = Path.join([
				scriptDirectory,
				scriptName,
				'.js',
				'?hotreload-cachebuster=${Date.now().getTime()}'
			]);
		 */
		var scriptPath = scriptDirectory + '/' + scriptName + '.js' + "?hotreload-cachebuster=" + Std.string(Date.now().getTime());

		// var scriptPath = './scripts/' + scriptName + '.js';
		// Emit 'unload' event for the old script instance
		// eventEmitter.emit('unload', scriptName);
		// unregister existing event listeners
		// eventEmitter.clearAll();
		// remove the cached version
		// Syntax.code("delete import.meta.resolveCache[scriptPath];");
		js.Lib.dynamicImport(scriptPath).then(m -> {
			// var updatedInstance = Syntax.code("eval('new ' + scriptName + '()')");
			var updatedInstance = createInstanceFromModule(m, scriptName);

			// onReloaded(scriptName, previousInstance, updatedInstance); // Call the callback with the newly created instance
			// Emit 'reload' event for the new script instance
			// eventEmitter.emit('reload', scriptName);
			onLoaded(updatedInstance);
		}).catchError(err -> {
			Log.debug('Error loading script: ' + err);
			onLoaded(null);
		});
	}

	public static function load(scriptName:String, onLoaded:String->Script->Script->Void):Void {
		if (scriptCache.exists(scriptName)) {
			onLoaded(scriptName, scriptCache.get(scriptName), null);
			return;
		}

		#if (debug && enable_script_reload)
		_load(scriptName, (scriptHost) -> {
			if (scriptHost != null) {
				// cache the script instance
				scriptCache.set(scriptName, scriptHost);
				onLoaded(scriptName, scriptHost, null);

				// Handle hot module replacement if Vite's HMR is enabled
				var hmr = js.Syntax.code("import.meta.hot");
				if (hmr != null) {
					// We should be able to use the hot module directly, but I can't get it to work
					// Instead, we'll use the ws connection from vite to custom message us when we should reload a script
					hmr.on('hotreload', function(data) {
						// Log.debug("in hot reload:", scriptName, scriptPath, data);
						var previousScriptInstance = scriptCache.get(scriptName);

						_load(scriptName, (updatedScriptInstance) -> {
							// cache the updated script instance
							scriptCache.set(scriptName, updatedScriptInstance);
							onLoaded(scriptName, updatedScriptInstance, previousScriptInstance);
						});
					});
				}
				// end hmr
			} else {
				Log.debug('Error loading script: ' + scriptName);
				onLoaded(scriptName, null, null);
			}
		});
		#else
		var scriptClass = Type.resolveClass(scriptName);
		if (scriptClass != null) {
			var scriptHost = Type.createInstance(scriptClass, []);
			onLoaded(scriptName, scriptHost, null);
			return;
		} else {
			Log.debug("Script " + scriptName + " not found.");
			onLoaded(scriptName, null, null); // Call the callback with the loaded instance
			return;
		}
		#end

		return;
	}
}
