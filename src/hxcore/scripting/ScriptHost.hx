package hxcore.scripting;

// import hxcore.stage.IStage;
// import hxcore.app.IApp;
// import haxe.macro.Type.Ref;
// import hxcore.util.TypeUtils;
import hxcore.events.EventEmitter;
// import hxcore.events.EventEmitterTracker;
import hxcore.logging.Log;
import hxcore.scripting.ScriptContext;
import hxcore.scripting.Script;



interface IScriptHost {
	public function dispatchEvent(eventId:String, ?eventData:Dynamic):Void;
	public function addEventListener(eventName:String, callback:EventListener):Void; 
	public function removeEventListener(eventName:String, callback:EventListener):Void; 
	public function removeEventListeners(eventName:String):Void; 
	public function removeAllEventListeners():Void; 

	public function invoke(functionName:String, ...args:Dynamic):Dynamic;
	public function setVar(key:String, value:Dynamic):Void;
	public function getVar(key:String):Dynamic;
}

class ScriptHost implements IScriptHost {
	private var script:Script;
	// private var _ctx:ScriptContext;
	private var ctx:ScriptContext;
	private var event:EventEmitter;

	// public var event:EventEmitterTracker;
	// public var event:EventEmitter;
	public var scriptName:String;

	public var scriptDirectory:String;

	private var scriptCreated:Bool;
	private var scriptLoaded:Bool;

	// public static var app:IApp;
	// public static var stage:IStage;
	// for dispatching events.  We reassign after loading a script
	// we could just use Reflection every time, but this is more efficient (?)
	private var dispatchEventFunc:(eventName:String, data:Dynamic) -> Void;

	public function new() {
		// this.scriptName = null;
		this.script = null;

		// this.dispatchEventFunc = null;
		// this.scriptDirectory = scriptDirectory;
		// this.event = new EventEmitter();
		// this.event = new EventEmitterTracker();
		// if (externalEventEmitter != null) {
		//	this.event.eventEmitter = externalEventEmitter;
		// }
		this.event = new EventEmitter();
		this.ctx = {};

		scriptCreated = false;
		scriptLoaded = false;
	}

	private function setScriptProperty(key:String, value:Dynamic) {
		if (this.script == null) {
			Log.error("Script not loaded");
			return;
		}

		if (!scriptCreated) {
			Log.error("Script not created");
			return;
		}

		Reflect.setProperty(this.script, key, value);
	}

	public function setScriptEnvironment() {
		// since scripts are single instances (essentialy singletons), we need set their instance variables before calling methods
			setScriptProperty("host", this);
			setScriptProperty("ctx", this.ctx);
	}

	public function getVar(key:String):Dynamic {
		return Reflect.getProperty(this.ctx, key);
		//return this.ctx[key];
	}

	public function setVar(key:String, value:Dynamic):Void {
		Reflect.setProperty(this.ctx, key, value);
		//this.ctx[key] = value;
	}

	public function loadScript(scriptName:String, ?onCreatedCallback:ScriptHost->Void, ?onLoadedCallback:ScriptHost->Void) {
		ScriptLoader.load(scriptName, (scriptName:String, loadedScript:Script) -> {
			var isReload = (this.script != null);
			if (loadedScript == null) {
				if (isReload) {
					// script was created before (but failed to reload)
					Log.warn("Failed to load script " + scriptName);
					scriptLoaded = false;
					if (onLoadedCallback != null) {
						onLoadedCallback(null);
					}
				} else {
					// script wasn't created before (and failed)
					Log.warn("Failed to create script " + scriptName);
					scriptCreated = false;
					scriptLoaded = false;
					if (onCreatedCallback != null) {
						onCreatedCallback(null);
					}
				}
				return;
			}

			this.scriptName = scriptName;
			scriptCreated = true;

			try {
				if (isReload) {
					// unload the previous script
					setScriptEnvironment();
					this.script._baseUnload();

					// set the new script env and reload
					this.script = loadedScript;
					// set the new script's context and let it load any data from the previously unloaded script
					setScriptEnvironment();
					loadedScript._baseReload();
					scriptLoaded = true;
				} else {
					// first time loading this script
					// set the new script env and reload
					this.script = loadedScript;

					if (onCreatedCallback != null) {
						onCreatedCallback(this);
					}
					setScriptEnvironment();
					loadedScript._baseLoad();
					scriptLoaded = true;
				}
				if (onLoadedCallback != null) {
					onLoadedCallback(this);
				}
				//Log.debug("scriptLoaded: " + scriptLoaded);

			} catch (e) {
				Log.error("Failed to load script: " + scriptName + " " + e.message);
				if (onLoadedCallback != null) {
					onLoadedCallback(null);
				}
				return;
			}
		});
	}

	public function invoke(functionName:String, ...args:Dynamic):Dynamic {
		if (this.script != null) {
			if (!scriptLoaded) {
				Log.warn('Unable to invoke function ${functionName}: Script not loaded');
				return null;
			}

			var func = Reflect.field(this.script, functionName);
			if (func != null) {
				setScriptEnvironment();
				return Reflect.callMethod(this.script, func, args);
			} else {
				Log.warn('Unable to invoke function ${functionName}: Function not found');
			}
		}
		return null;
	}

	public function dispatchEvent(eventId:String, ?eventData:Dynamic):Void {
		if (!scriptLoaded) {
			Log.warn('Unable to dispatch event ${eventId}: Script not loaded');
			return;
		}
		setScriptEnvironment(); // hmm.. this doesn't seem right
		this.event.emit(eventId, eventData);
	}

	public function addEventListener(eventId:String, callback:EventListener) {
		// springboard so we can use strings for function names and lookup the actual function with Reflection
			// disabled for now, since we lose the ability to remove the eventlistener (it's in a closure)
		//var eventListener = (args:Dynamic) -> {
		//	this.invoke(callback, args);
		//}
		//this.event.on(eventId, eventListener);
		this.event.on(eventId, callback);
	}

	public function removeEventListener(eventId:String, callback:EventListener) {
		this.event.off(eventId, callback);
		// hmm.. the event callback use to be a function name and registered in a closure
		// but we don't know the function pointer outside that closure, so we can't remove it
		// for now, we'll just leave it in the event emitter and force the script to re-add after a reload
	}

	public function removeEventListeners(eventId:String) {
		this.event.clear(eventId);
	}

	public function removeAllEventListeners() {
		this.event.clearAll();
	}

	public function dispose() {

		if (this.script != null && scriptLoaded) {
			setScriptEnvironment();
			this.script._baseUnload();
		}
		scriptCreated = false;
		scriptLoaded = false;
		this.script = null;
		this.ctx = null;
		this.event = null;
		this.scriptName = 'unknown';
	}

	public function update(deltaTimeMS:Float):Void {
		if (this.script != null && scriptLoaded) {
			setScriptEnvironment();
			this.script._baseUpdate(deltaTimeMS);
		}
	}

	public function fixedUpdate(frameDurationMS:Float):Void {
		if (this.script != null && scriptLoaded) {
			setScriptEnvironment();
			this.script._baseFixedUpdate(frameDurationMS);
		}
	}
}
