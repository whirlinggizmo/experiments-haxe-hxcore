package core.scripting;

import core.logging.Log;
import core.util.TypeUtils;

class ScriptLoader {
	/**
	 * Loads a script by name for non-JS targets using Haxe reflection.
	 * 
	 * @param scriptName The name of the script to load.
	 * @return A new instance of the script.
	 */
	private static var scriptCache:Map<String, Script> = new Map<String, Script>();
	public static var scriptDirectory:String = "./scripts/";
	public static var scriptSourceDirectory:String = "./src/";

	public static function load(scriptName:String, onLoaded:String->Script->Void):Void {
		if (scriptCache.exists(scriptName)) {
			onLoaded(scriptName, scriptCache.get(scriptName));
			return;
		}

		// TODO: do we want to include the script directory as the package, or add the script directory class path when building?
		//var fullScriptName = scriptsRootDirectory + '.' + scriptName; 
		var fullScriptName = scriptName;

		var scriptClass = Type.resolveClass(fullScriptName);
		if (scriptClass != null) {
			// ensure it derives from Script
			if (!TypeUtils.isDerivedFrom(scriptClass, core.scripting.Script)) {
				Log.error("Script " + scriptName + " does not derive from core.scripting.Script");
				if (onLoaded != null) {
					onLoaded(scriptName, null); // Call the callback with the loaded instance 
				}
				return;
			}

			Log.debug('scriptClass: $scriptClass');
			var script = Type.createInstance(scriptClass, []);

			if (script == null) {
				Log.error('Error creating script instance: ' + fullScriptName);
				if (onLoaded != null) {
					onLoaded(scriptName, null); // Call the callback with the loaded instance 
				}
				return;
			}

			// cache the script instance
			scriptCache.set(scriptName, script);
			script.scriptName = scriptName; 
			script.scriptDirectory = scriptDirectory;
			if (onLoaded != null) {
				onLoaded(scriptName, script); // Call the callback with the loaded instance
			}
			return;
		} else {
			Log.error('Unable to resolve script: ' + fullScriptName);
			if (onLoaded != null) {
				onLoaded(scriptName, null); // Call the callback with the loaded instance 
			}
			return;
		}
	}
}
