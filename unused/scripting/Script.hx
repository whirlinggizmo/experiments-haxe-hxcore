// import EventEmitter.EventEmitterTracker;
import EventEmitter.EventEmitter;

@:keep
@:keepSub
@:expose
class Script {
	// instance variables that need to be set by the script's controller
	public var event:EventEmitter; // set by the script's controller
	public var ctx:ScriptContext; // set by the script's controller
	public var app:tests.heaps.MainApp;

	//
	private var scriptOnInit:Dynamic;
	private var scriptOnLoad:Dynamic;
	private var scriptOnUnload:Dynamic;
	private var scriptOnDestroy:Dynamic;
	private var scriptOnUpdate:Dynamic;

	public inline function log(s:Dynamic, ?pos:haxe.PosInfos) {
		// write(s, LogLevel.Debug, pos);
		if (pos != null) {
			haxe.Log.trace('${pos.fileName}:${pos.lineNumber}:' + Std.string(s), null);
		} else {
			haxe.Log.trace(s);
		}
	}

	public function new() {
		// this.event = new EventEmitterTracker();
		Logger.replaceTrace();

		// check if any derived classes have their own onXYZ methods
		this.scriptOnInit = Reflect.field(this, "onInit");
		this.scriptOnLoad = Reflect.field(this, "onLoad");
		this.scriptOnUnload = Reflect.field(this, "onUnload");
		this.scriptOnDestroy = Reflect.field(this, "onDestroy");
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
			trace("No custom onInit defined for this script.");
		}
	}
	*/

	// The base onUnload method, which calls the script's onUnload if it exists
	public function _baseUnload():Void {
		// Check if the script class has its own onUnload method and call it if it exists
		// var unloadMethod = Reflect.field(this, "onUnload");
		if (this.scriptOnUnload != null) {
			// Reflect.callMethod(this, unloadMethod, [ctx]);
			this.scriptOnUnload();
			// trace('context = ${this.ctx}');
		} else {
			// Default behavior if no custom onUnload exists
			trace("No custom onUnload defined for this script.");
		}
		// if (this.event != null) {
		// 	this.event.clearAll();
		//  }
	}

	// The base onLoad method, which calls the script's onLoad if it exists
	public function _baseLoad():Void {

		this.app = this.ctx.app;

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

	public function _baseReload():Void {

		this.app = this.ctx.app;

		// Check if the script class has its own onLoad method and call it if it exists
		// var loadMethod = Reflect.field(this, "onLoad");
		if (this.scriptOnLoad != null) {
			// Reflect.callMethod(this, loadMethod, [ctx]);
			this.scriptOnReload();
		} else {
			// Default behavior if no custom onLoad exists
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
