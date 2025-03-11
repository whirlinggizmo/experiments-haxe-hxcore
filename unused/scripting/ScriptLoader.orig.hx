package core.scripting;

class ScriptLoader {
	/**
	 * Loads a script by name for non-JS targets using Haxe reflection.
	 * 
	 * @param scriptName The name of the script to load.
	 * @param eventEmitter The event emitter to handle script lifecycle events.
	 * @return A new instance of the script.
	 */
	public static function load(scriptName:String, eventEmitter:EventEmitter, onLoad:Dynamic->Void):Void {
		// var scriptPath = './scripts/' + scriptName + '.js';

		var scriptClass = Type.resolveClass(scriptName);
		if (scriptClass != null) {
			var scriptInstance = Type.createInstance(scriptClass, []);
			onLoad(scriptInstance); // Call the callback with the loaded instance
		} else {
			log.debug("Script " + scriptName + " not found.");
			return;
		}
	}
}
