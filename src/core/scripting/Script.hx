package core.scripting;

// import core.stage.IStage;
// import core.app.IApp;
// import core.events.EventEmitter;
// import core.events.EventEmitterTracker;
import core.events.EventEmitter.EventListener;
import core.logging.Log;
import core.scripting.ScriptContext;
import core.scripting.ScriptHost;

/**
 * Base class for scripts
 * Note to self: This (and all other derived classes) are STATELESS.  The actual script is a single instance, held by the ScriptLoader.
 * Whenever script methods are invoked, you must set the instance variables on the script from its controller ( a ScriptHost, aka Host).  
 * Think of it like the scripts themselves are singletons or static.  Whatever property you last set will be used for the next script user.  
 * This is doubly important when dealing with the Script base class, since ALL scripts derive from it.
 * We could do away with the ScriptHost and just use instances of the scripts directly, but then hot reloading becomes a pain.
 */

@:keep
@:keepSub
@:expose
class Script {
	// instance variables that need to be set by the script's controller
	public var host:IScriptHost;
	public var ctx:ScriptContext;
	//public var app:Dynamic;  // TODO:  Interface for IApp?

	//@:allow(core.scripting.ScriptLoader)
	public var scriptName:String = "SCRIPT"; // replaced by the ScriptLoader when it loads the script
	//@:allow(core.scripting.ScriptLoader)
	public var scriptDirectory:String = ""; // replaced by the ScriptLoader when it loads the script

	public inline function log(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String) {
		/*
		var p:haxe.PosInfos = {
			fileName: scriptDirectory + '/' + pos.fileName,
			lineNumber: pos?.lineNumber ?? 0,
			customParams: pos?.customParams ?? null,
			methodName: pos?.methodName ?? "",
			className: pos?.className ?? scriptName
		};
		*/
		Log.log(s, pos, (tag == null ? 'SCRIPT: ${scriptName}' : tag));
	}
	
	public function addEventListener(eventName:String, callback:EventListener):Void {
		Log.debug("Adding event listener: " + eventName);
		this.host?.addEventListener(eventName, callback);
	}

	public function removeEventListener(eventName:String, callback:EventListener):Void {
		Log.debug("Removing event listener: " + eventName);
		this.host?.removeEventListener(eventName, callback);
	}

	public function dispatchEvent(eventName:String, ?data:Dynamic):Void {
		Log.debug("Dispatching event: " + eventName);
		this.host?.dispatchEvent(eventName, data);
	}

	public function removeEventListeners(eventId:String):Void {
		this.host?.removeEventListeners(eventId);
	}

	public function removeAllEventListeners():Void {
		this.host?.removeAllEventListeners();
	}

	public function new() {
		this.ctx = null;
		this.host = null;
	}

	public function setHooks():Void {
		// check if any derived classes have their own onXYZ methods
		// this.scriptOnInit = Reflect.field(this, "onInit");
		// this.scriptOnLoad = Reflect.field(this, "onLoad");
		// this.scriptOnUnload = Reflect.field(this, "onUnload");
		// this.scriptOnDestroy = Reflect.field(this, "onDestroy");
		// this.scriptOnReload = Reflect.field(this, "onReload");
	}

	// The base init method, which calls the script's init if it exists
	/*
		public function _baseInit():Void {
			// this.externalEventEmitter = eventEmitter;
			// if (this.event != null) {
			//	this.event.eventEmitter = eventEmitter;
			// }
			// Check if the script class has its own onInit method and call it if it exists
			// var initMethod = Reflect.field(this, "onInit");
			if (this.scriptOnInit != null) {
				this.scriptOnInit();
				// Reflect.callMethod(this, initMethod, [ctx]);
			} else {
				// Default behavior if no custom initScript exists
				Log.debug("No custom onInit defined for this script.");
			}
		}
	 */
	// The base onUnload method, which calls the script's onUnload if it exists
	public function _baseUnload():Void {
		this.onUnload();
		// since the event listener functions can change after an unload, we need to clear them
		this.host?.removeAllEventListeners();

		// if (this.event != null) {
		// 	this.event.clearAll();
		// }
	}

	// The base onLoad method, which calls the script's onLoad if it exists
	public function _baseLoad():Void {
		// this.app = this.ctx.app;
		// this.event = this.ctx.event;
		this.onLoad();
	}

	// The base onReload method, which calls the script's onReload if it exists
	public function _baseReload():Void {
		// this.app = this.ctx.app;
		// this.event = this.ctx.event;
		this.onReload();
	}

	// The base destroy method, which calls the script's destroy if it exists
	/*
		public function _baseDestroy():Void {
			// Check if the script class has its own onDestroy method and call it if it exists
			// var destroyMethod = Reflect.field(this, "onDestroy");
			if (this.scriptOnDestroy != null) {
				// Reflect.callMethod(this, destroyMethod, [ctx]);
				this.scriptOnDestroy();
			} else {
				// Default behavior if no custom onDestroy exists
				Log.debug("No custom onDestroy defined for this script.");
			}
		}
	 */
	// The base update method, which calls the script's update if it exists
	/*
		public function _baseUpdate(deltaTimeMS:Float):Void {
			// Check if the script class has its own onUpdate method and call it if it exists
			// var updateMethod = Reflect.field(this, "onUpdate");
			if (this.scriptOnUpdate != null) {
				// Reflect.callMethod(this, destroyMethod, [ctx]);
				this.scriptOnUpdate(deltaTimeMS);
			} else {
				// Default behavior if no custom onUpdate exists
				Log.debug("No custom onUpdate defined for this script.");
			}
		}
	 */
	// overrides for derived classes
	public function onLoad():Void {}

	public function onUnload():Void {}

	public function onReload():Void {}
}
