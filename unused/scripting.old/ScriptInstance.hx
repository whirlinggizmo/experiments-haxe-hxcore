package core.scripting;

import core.stage.IStage;
import core.app.IApp;
import core.events.EventEmitter;
import core.events.EventEmitterTracker;
import core.logging.Log;

class ScriptHost {
	public var script:Script;
	public var ctx:ScriptContext;
	public var event:EventEmitterTracker;
	public var scriptName:String;
	public static var app:IApp;
	public static var stage:IStage;


	public function new(externalEventEmitter:EventEmitter = null) {
		this.scriptName = null;
		this.script = null;
		this.event = new EventEmitterTracker();
		if (externalEventEmitter != null) {
			this.event.eventEmitter = externalEventEmitter;
		}
		this.ctx = ScriptContext.create();
	}

	public function setApp(app:IApp) {
		ScriptHost.app = app;
	}

	public function setStage(stage:IStage) {
		ScriptHost.stage = stage;
	}

	public function setScriptEnvironment(script:Script) {
		// since scripts are single instances (essentialy singletons), we need set their instance variables before calling methods
		if (script != null) {
			script.event = this.event;
			script.ctx = this.ctx;
			script.name = this.scriptName;
			script.app = ScriptHost.app;
			script.stage = ScriptHost.stage;
			// set other instance variables here
		}
	}

	public function setContext(ctx:ScriptContext) {
		this.ctx = ctx;
	}

	public function getContext():ScriptContext {
		return this.ctx;
	}

	public function setContextValue(key:String, value:Dynamic) {
		this.ctx[key] = value;
	}

	public function loadScript(scriptName:String, ?onCreatedCallback:ScriptHost->Void, ?onLoadedCallback:ScriptHost->Void) {
		this.scriptName = scriptName;
		ScriptLoader.load(scriptName, (scriptName, scriptHost, previousScriptInstance) -> {
			if (scriptHost != null) {
				if (this.script != null) {
					// unload the previous script
					unloadScript();
					this.script = scriptHost;
					// set the new script's context and let it load any data from the previously unloaded script
					setScriptEnvironment(scriptHost);
					scriptHost._baseReload();
				} else {
					// first time loading this script
					this.script = scriptHost;
					if (onCreatedCallback != null) {
						onCreatedCallback(this);
					}
					setScriptEnvironment(scriptHost);
					scriptHost._baseInit();
					scriptHost._baseLoad();
				}
				if (onLoadedCallback != null) {
					onLoadedCallback(this);
				}
			} else {
				Log.debug("Failed to load script " + scriptName);
				if (onLoadedCallback != null) {
					onLoadedCallback(null);
				}
			}
		});
	}

	public function unloadScript() {
		if (this.script != null) {
			setScriptEnvironment(this.script);
			this.script._baseUnload();
		}

		this.event.clearAll();
	}

	/*
		function emit(eventName:String, data:Dynamic) {
			if (this.script != null) {
				this.event.emit(eventName, data);
			}
		}

		function on(eventName:String, listener:Dynamic->Void) {
			if (this.script != null) {
				this.event.on(eventName, listener);
			}
		}

		function off(eventName:String, listener:Dynamic->Void) {
			if (this.script != null) {
				this.event.off(eventName, listener);
			}
		}
	 */
	public function callFunction(functionName:String, ...args:Dynamic):Dynamic {
		if (this.script != null) {
			var func = Reflect.field(this.script, functionName);
			if (func != null) {
				setScriptEnvironment(this.script);
				//return func(args);
				//return func.apply(this.script, args);
				// if length of args > 1, we need to spread them.  Use reflection
				return Reflect.callMethod(this.script, func, args); 
			}
		}
		return null;
	}

	public function dispose() {
		unloadScript();
		this.script = null;
		this.ctx = null;
		this.event = null;
		this.scriptName = null;
	}
}
