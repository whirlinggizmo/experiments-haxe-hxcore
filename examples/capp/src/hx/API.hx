package;

import hxcore.scripting.ScriptRuntime;
import hxcore.ecs.Entity;
import hxcore.ecs.EntityManager;
import hxcore.ecs.EntityID;
import hxcore.logging.Log;
import hxcore.util.FPSCounter;

@:expose
@:keep
@:build(HaxeCBridge.expose())
class API {
	public function new() {}
	private var runtime:ScriptRuntime;
	

	public function init(?scriptDirectory:String = null, ?scriptSourceDirectory:String = null, ?enableHotReload:Bool = false) {
		Log.info('Hello, World!');

		runtime = ScriptRuntime.getDefault();

		if (scriptDirectory != null && scriptDirectory.length > 0) {
			runtime.config.scriptOutputRoot = scriptDirectory;
			runtime.config.externalEnabled = true;
		}

		if (scriptSourceDirectory != null && scriptSourceDirectory.length > 0) {
			if (scriptDirectory == null || scriptDirectory.length == 0) {
				Log.error('Error: hot compile requires the script directory (for the compiled scripts)');
				return;
			}
			runtime.config.scriptSourceRoot = scriptSourceDirectory;
			runtime.config.hotCompileEnabled = true;
		}

		if (enableHotReload) {
			if (scriptDirectory == null || scriptDirectory.length == 0) {
				Log.error('Error: hot reload requires the script directory (for the compiled scripts)');
				return;
			}
			runtime.config.hotReloadEnabled = true;
		}

		runtime.applyConfig();
	}

	private var quitFlag:Bool = false;
	public function quit() {
		quitFlag = true;
	}

	public function update(deltaTimeMS:Float):Bool {
		FPSCounter.addFrame(deltaTimeMS);
		return quitFlag || EntityManager.update(deltaTimeMS);
	}

	/**
	 * Tick the update loop.  
	 * Call this instead of update() if you don't have a delta time
	 * Alternatively, use the hxcore.util.UpdateHandler() helper
	 */
	var lastUpdateTime:Float;
	var currentTime:Float;
	var deltaTimeMS:Float;
	public function tick():Bool {
		currentTime = haxe.Timer.stamp();
		deltaTimeMS = (currentTime - lastUpdateTime) * 1000.0;
		lastUpdateTime = currentTime;
		return update(deltaTimeMS);
	}


	public function destroy() {
		EntityManager.clear();

		// shut down the script loader
		runtime.dispose();

		Log.info('Goodbye, World!');
	}

	public function createEntity(scriptName:String):EntityID {
		var entity = EntityManager.createEntity();

		// Attach the script to the entity
		entity.attachScript(scriptName, (scriptInstance) -> {
			if (scriptInstance == null) {
				Log.error("Failed to create script: " + scriptName);
				return;
			}
		}, (scriptInstance) -> {
			if (scriptInstance == null) {
				Log.error("Failed to load script: " + scriptName);
				return;
			}
		});

		return entity.eid;	
	}

	public function destroyEntity(entityId:EntityID) {
		EntityManager.destroyEntity(entityId);
	}

	public function run() {
		var updateHandler = new hxcore.util.UpdateHandler();
		updateHandler.run({
			onUpdateCallback: update,
			updateRateFPS: 60,
			onQuitCallback: destroy
		});
	}

	public static function main() {
		//new API('scripts', null, true);
	}
}
