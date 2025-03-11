import js.Syntax;
import js.lib.Promise;

class ScriptLoader {
	static function createInstanceFromModule(m, className) {
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
		");

		trace('Error creating script instance from module script: $className');
		return null;
	}

	public static function reload(scriptName:String, onReload:String->Dynamic->Void):Void {
		// use a cache buster to force the browser to reload
		// This should be possible with vite HMR and accept(), but I can't seem to get it to work
		var scriptPath = './scripts/' + scriptName + '.js' + "?hotreload-cachebuster=" + Std.string(Date.now().getTime());
		// var scriptPath = './scripts/' + scriptName + '.js';

		trace("Reloading script: " + scriptName);

		// Emit 'unload' event for the old script instance
		// eventEmitter.emit('unload', scriptName);

		// unregister existing event listeners
		// eventEmitter.clearAll();

		// remove the cached version
		// Syntax.code("delete import.meta.resolveCache[scriptPath];");
		js.Lib.dynamicImport(scriptPath).then(m -> {
			// var updatedInstance = Syntax.code("eval('new ' + scriptName + '()')");
			var updatedInstance = createInstanceFromModule(m, scriptName);

			onReload(scriptName, updatedInstance); // Call the callback with the loaded instance

			// Emit 'reload' event for the new script instance
			// eventEmitter.emit('reload', scriptName);
		}).catchError(err -> {
			trace('Error reloading script: ' + err);
		});
	}

	public static function load(scriptName:String, eventEmitter:EventEmitter, onLoad:String->Dynamic->Void, onReload:String->Dynamic->Void):Void {
		var scriptPath = './scripts/' + scriptName + '.js';

		js.Lib.dynamicImport(scriptPath).then((m) -> {
			var instance = null;

			instance = createInstanceFromModule(m, scriptName);
			// var instance = Syntax.code("eval('new ' + scriptName + '()')");

			// Emit 'load' event when the script is first loaded
			// eventEmitter.emit('load', scriptName);

			// Handle hot module replacement if Vite's HMR is enabled
			var hot = js.Syntax.code("import.meta.hot");
			if (hot != null) {
				// We should be able to use the hot module directly, but I can't get it to work
				// Instead, we'll use the ws connection from vite to custom message us when we should reload a script
				hot.on('hotreload', function(data) {
					// trace("in hot reload:", scriptName, scriptPath, data);
					reload(scriptName, onReload);
				});
			}

			onLoad(scriptName, instance); // Call the callback with the loaded instance
		}).catchError(err -> {
			trace('Error loading script: ' + err);
			onLoad(null, null); // In case of error, return null in callback
		});
	}
}
