package core.scripting;

import core.stage.IStage;
import core.app.IApp;
import core.events.EventEmitter;
// import core.events.EventEmitterTracker;
import core.logging.Log;

@:keep
@:keepSub
@:expose
class Script {
	// instance variables that need to be set by the script's controller
	public var event:EventEmitter; // set by the script's controller
	public var ctx:ScriptContext; // set by the script's controller
	public var name:String = "SCRIPT";
	public var stage:IStage = null;
	public var app:IApp = null;

	//
	private var scriptOnInit:Dynamic;
	private var scriptOnLoad:Dynamic;
	private var scriptOnReload:Dynamic;
	private var scriptOnUnload:Dynamic;
	private var scriptOnDestroy:Dynamic;
	private var scriptOnUpdate:Dynamic;

	public inline function log(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String) {
		Log.log(s, pos, (tag == null ? 'SCRIPT (${name})' : tag));
	}

	public function new() {
		// this.event = new EventEmitterTracker();
		this.event = new EventEmitter();

		// event = null;
		ctx = null;

		stage = null;
		app = null;

		// check if any derived classes have their own onXYZ methods
		this.setHooks();
	}

	public function setHooks():Void {
		// check if any derived classes have their own onXYZ methods
		this.scriptOnInit = Reflect.field(this, "onInit");
		this.scriptOnLoad = Reflect.field(this, "onLoad");
		this.scriptOnUnload = Reflect.field(this, "onUnload");
		this.scriptOnDestroy = Reflect.field(this, "onDestroy");
		this.scriptOnReload = Reflect.field(this, "onReload");
	}

	// The base init method, which calls the script's init if it exists
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

	// The base onUnload method, which calls the script's onUnload if it exists
	public function _baseUnload():Void {
		// Check if the script class has its own onUnload method and call it if it exists
		// var unloadMethod = Reflect.field(this, "onUnload");
		if (this.scriptOnUnload != null) {
			// Reflect.callMethod(this, unloadMethod, [ctx]);
			this.scriptOnUnload();
			// Log.debug('context = ${this.ctx}');
		} else {
			// Default behavior if no custom onUnload exists
			Log.debug("No custom onUnload defined for this script.");
		}
		// if (this.event != null) {
		// 	this.event.clearAll();
		//  }
	}

	// The base onLoad method, which calls the script's onLoad if it exists
	public function _baseLoad():Void {
		// Check if the script class has its own onLoad method and call it if it exists
		// var loadMethod = Reflect.field(this, "onLoad");
		if (this.scriptOnLoad != null) {
			// Reflect.callMethod(this, loadMethod, [ctx]);
			this.scriptOnLoad();
		} else {
			// Default behavior if no custom onLoad exists
			Log.debug("No custom onLoad defined for this script.");
		}
	}

	// The base onReload method, which calls the script's onReload if it exists
	public function _baseReload():Void {
		// Check if the script class has its own onReload method and call it if it exists
		// var loadMethod = Reflect.field(this, "onReload");
		if (this.scriptOnReload != null) {
			// Reflect.callMethod(this, loadMethod, [ctx]);
			this.scriptOnReload();
		} else {
			// Default behavior if no custom onReload exists
			Log.debug("No custom onReload defined for this script.");
		}
	}

	// The base destroy method, which calls the script's destroy if it exists
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

	// The base update method, which calls the script's update if it exists
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
}
