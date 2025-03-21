package core.ecs;

import core.ecs.EntityID.EIDGenerator;
import core.scripting.ScriptHost;
import core.scripting.ScriptContext;
import core.events.EventEmitter;
import core.logging.Log;

@:export
@:keep
class Entity {
	private var scripts:Map<String, ScriptHost> = new Map(); // Holds loaded scripts by name

	// public var event(default, null):EventEmitter = new EventEmitter(); // Manages events
	public var ctx = {}; // ScriptContext.create(); // Holds script context

	public var id:String;

	private var _eid:EntityID;

	public var eid(get, null):EntityID;

	function get_eid() {
		return this._eid;
	}

	public function new(?eid:EntityID) {
		if (eid != null) {
			this._eid = eid;
		} else {
			this._eid = EIDGenerator.nextEID();
		}
		Log.debug('Entity ${this._eid} created');
	}

	/**
	 * Attaches a script to the entity by name.
	 * The script will be loaded dynamically via ScriptLoader.
	 * 
	 * @param scriptName The name of the script to attach.
	 */
	public function attachScript(scriptName:String, ?onCreatedCallback:ScriptHost->Void, ?onLoadedCallback:ScriptHost->Void):Void {
		if (scripts.exists(scriptName)) {
			Log.warn("Script " + scriptName + " already attached to entity " + this.id);
			if (onLoadedCallback != null) {
				onLoadedCallback(scripts.get(scriptName));
			}
			return;
		}

		try {
			var instance = new ScriptHost();
			instance.loadScript(scriptName, (instance) -> {
				// preinit
				if (instance != null) {
					// Log.debug('in attachScript.created callback');
					// Store the script instance
					scripts.set(scriptName, instance);
					Log.debug("Created script: " + scriptName);

					// override the script context with ours?
					// instance.setContextValue("ctx", this.ctx);

					// let the caller know the script has been created
					if (onCreatedCallback != null) {
						onCreatedCallback(instance);
					}
				} else {
					Log.warn("Failed to create script: " + scriptName);
					if (onCreatedCallback != null) {
						onCreatedCallback(null);
					}
				}
			}, (instance) -> {
				// loaded
				// Log.debug('in attachScript.loaded callback');

				if (instance != null) {
					// let the caller know the script has been loaded and attached
					if (onLoadedCallback != null) {
						onLoadedCallback(instance);
					}
				} else {
					Log.warn("Failed to load script: " + scriptName);
					if (onLoadedCallback != null) {
						onLoadedCallback(null);
					}
				}
			});
		} catch (e) {
			Log.error("Failed to attach script: " + scriptName);
			if (onLoadedCallback != null) {
				onLoadedCallback(null);
			}
		}
	}

	/**
	 * Detaches the script with the specified name from the entity.
	 * 
	 * @param scriptName The name of the script to detach.
	 */
	public function detachScript(scriptName:String):Void {
		var scriptHost = scripts.get(scriptName);
		if (scriptHost != null) {
			scriptHost.dispose();
			Log.debug("Detached script: " + scriptName);
		}
		scripts.remove(scriptName);
		Log.debug("Removed script: " + scriptName);
	}

	/**
	 * Invokes a method on a specific script attached to the entity.  Probably don't want to use this, emit an event instead.
	 * 
	 * @param scriptName The name of the script.
	 * @param functionName The method to invoke on the script.
	 * @param args Arguments to pass to the method.
	 */
	public function invoke(scriptName:String, functionName:String, args:Array<Dynamic>):Dynamic {
		var scriptHost = scripts.get(scriptName);
		if (scriptHost != null) {
			// var method = Reflect.field(scriptHost, functionName);
			// if (method != null) {
			//		return Reflect.callMethod(scriptHost, method, args);
			//	} else {
			//		Log.debug("Method " + functionName + " not found on script " + scriptName);
			//	}
			return scriptHost.invoke(functionName, args);
		} else {
			Log.debug("Script " + scriptName + " not found on entity");
		}
		return null;
	}

	public function dispose():Void {
		// Detach all scripts
		for (scriptName in scripts.keys()) {
			detachScript(scriptName);
		}
	}

	public function dispatchEvent(eventName:String, ?data:Dynamic):Void {
		for (script in scripts) {
			script.dispatchEvent(eventName, data);
		}
	}
}
