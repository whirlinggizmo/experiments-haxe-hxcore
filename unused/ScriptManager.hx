class ScriptManager {
	private static var cache:Map<String, Script> = new Map();

	/**
	 * Retrieves a script by name, handles caching, and initialization.
	 * 
	 * @param scriptName The name of the script to load.
	 * @param eventEmitter The event emitter to handle script lifecycle events.
	 * @param onLoad Callback function to handle the loaded script.
	 */
	public static function loadScript(scriptName:String, eventEmitter:EventEmitter, onLoad:Dynamic->Void):Void {
		if (cache.exists(scriptName)) {
			onLoad(cache.get(scriptName));
		} else {
			ScriptLoader.load(scriptName, function(scriptName, scriptInstance, previousScriptInstance) {
				if (scriptInstance != null) {
					cache.set(scriptName, scriptInstance);

					// Invoke the base init method if it exists
					// var initMethod = Reflect.field(script, "_baseInit");
					// if (initMethod != null) {
					//	Reflect.callMethod(script, initMethod, [eventEmitter]);
					// }
					scriptInstance._baseInit();
				}
				onLoad(scriptInstance);
			});
			/*, function(scriptName, scriptInstance) {
					if (scriptInstance != null) {
						var ctx:Dynamic = {};
						if (cache.exists(scriptName)) {
							var previousInstance = cache.get(scriptName);
							previousInstance._baseUnload();
							ctx = previousInstance?.ctx;
							cache.remove(scriptName);
						}

						scriptInstance.ctx = ctx;
						cache.set(scriptName, scriptInstance);
						scriptInstance._baseReload();
					}
				});
			 */
		}
	}

	public static function unloadScript(scriptName:String):Void {
		if (cache.exists(scriptName)) {
			var script = cache.get(scriptName);
			// var destroyMethod = Reflect.field(script, "_baseDestroy");
			// if (destroyMethod != null) {
			// Reflect.callMethod(script, destroyMethod, []);
			script._baseUnload();
			// }
		}
		cache.remove(scriptName);
	}

	public static function destroyScript(scriptName:String):Void {
		if (cache.exists(scriptName)) {
			var script = cache.get(scriptName);
			// var destroyMethod = Reflect.field(script, "_baseDestroy");
			// if (destroyMethod != null) {
			// Reflect.callMethod(script, destroyMethod, []);
			script._baseDestroy();
			// }
		}
		cache.remove(scriptName);
	}

	public static function clearAllCache():Void {
		cache = new Map();
	}

	public function invokeScriptMethod(scriptName:String, functionName:String, args:Array<Dynamic>):Dynamic {
		var script = cache.get(scriptName);
		if (script == null) {
			trace("Script " + scriptName + " not found in cache");
			return null;
		}

		var method = Reflect.field(script, functionName);
		if (method == null) {
			trace("Method " + functionName + " not found on script " + scriptName);
		}

		var ctx = script; // TODO:  Add support for per entity context?
		return Reflect.callMethod(ctx, method, args);
	}
}
