package core.scripting;
import core.logging.Log;

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
			var script = Type.createInstance(scriptClass, []);
			if (onLoaded != null) {
				onLoaded(scriptName, script, null); // Call the callback with the loaded instance (no hot reload, so no previous instance)
			}
			return;
		} else {
			Log.debug("Script " + scriptName + " not found.");
			if (onLoaded != null) {
				onLoaded(scriptName, null, null); // Call the callback with the loaded instance (no hot reload, so no previous instance)
			}
			return;
		}
	}
}
