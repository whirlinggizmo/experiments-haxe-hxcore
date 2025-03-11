import EventEmitter.EventEmitterTracker;

class ScriptInstance {
	public var script:Script;
	public var ctx:ScriptContext;
	public var event:EventEmitterTracker;
	public var scriptName:String;

	public function new(externalEventEmitter:EventEmitter = null) {
		this.scriptName = null;
		this.script = null;
		this.event = new EventEmitterTracker();
		if (externalEventEmitter != null) {
			this.event.eventEmitter = externalEventEmitter;
		}
		this.ctx = ScriptContext.create();
	}

	public function setScriptEnvironment(script:Script) {
		// since scripts are single instances (essentialy singletons), we need set their instance variables before calling methods
		if (script != null) {
			script.event = this.event;
			script.ctx = this.ctx;
			// set other instance variables here
		}
	}

	public function setContext(ctx:ScriptContext) {
		this.ctx = ctx;
	}

	public function loadScript(scriptName:String, onInitialized:ScriptInstance->Void, onLoaded:ScriptInstance->Void) {
		this.scriptName = scriptName;
		ScriptLoader.load(scriptName, (scriptName, scriptInstance, previousScriptInstance) -> {
			if (scriptInstance != null) {
				if (this.script != null) {
					// unload the previous script
					unloadScript();
					// set the new script's context and let it load any data from the previously unloaded script
					setScriptEnvironment(scriptInstance);
					scriptInstance._baseLoad();
				} else {
					setScriptEnvironment(scriptInstance);
					scriptInstance._baseInit();
					if (onInitialized != null) {
						onInitialized(this);
					}
					scriptInstance._baseLoad();
				}
				this.script = scriptInstance;
				onLoaded(this);
			} else {
				trace("Failed to load script " + scriptName);
				onLoaded(null);
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
	public function callFunction(functionName:String, args:Array<Dynamic>):Dynamic {
		if (this.script != null) {
			// Reflect.callMethod(this.script, Reflect.field(this.script, methodName), args);
			var func = Reflect.field(this.script, functionName);
			if (func != null) {
				setScriptEnvironment(this.script);
				return func(this.ctx, args);
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
