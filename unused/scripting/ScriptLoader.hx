class ScriptLoader {
	/**
	 * Loads a script by name for non-JS targets using Haxe reflection.
	 * 
	 * @param scriptName The name of the script to load.
	 * @return A new instance of the script.
	 */
	public static function load(scriptName:String, onLoaded:String->Script->Script->Void):Void {
		// var scriptPath = './scripts/' + scriptName + '.js';

		var scriptClass = Type.resolveClass(scriptName);
		if (scriptClass != null) {
			var scriptInstance = Type.createInstance(scriptClass, []);
			// call the base init method
			// scriptInstance._baseInit();
			onLoaded(scriptName, scriptInstance, null); // Call the callback with the loaded instance (no hot reload, so no previous instance)
			return;
		} else {
			trace("Script " + scriptName + " not found.");
			onLoaded(scriptName, null, null); // Call the callback with the loaded instance

			return;
		}
	}
}
