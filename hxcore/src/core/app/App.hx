package core.app;

import haxe.MainLoop;
import haxe.Exception;
import haxe.Timer;
import core.actor.ActorRegistry;
import core.camera.Camera;
import core.ui.UIOverlay;
import core.stage.IStage;
import core.logging.Log;
import core.app.IApp;

class App implements IApp {
	var camera:Camera;
	var totalElapsedTimeSec:Float = 0.0;
	var lastFrameTimeSec:Float = 0.0;
	var currentFrameTimeSec:Float = 0.0;
	var deltaTimeMS:Int = 0;
	var quitFlag = false;
	// var mainLoopEvent:MainEvent;
	var stage:IStage;
	var frameRate:Int;
	var isInitialized = false;

	public function new() {}

	public function init(stage:IStage, ?options:AppOptions):Void {
		Log.debug('Initializing...');
		options ??= {};
		this.stage = stage;
		quitFlag = false;

		//camera = new Camera();
		//stage.setCamera(camera);

		var rootActorId = ActorRegistry.createActor();
		ActorRegistry.addComponent(rootActorId, "position", {x: 0, y: 0, z: 0});

		stage.addActor(rootActorId);

		lastFrameTimeSec = Timer.stamp();
		totalElapsedTimeSec = 0.0;

		isInitialized = true;
	}

	public function update(deltaTimeMS:Int):Int {
		try {
			//Log.debug('Updating...');
			var err = stage.update(deltaTimeMS);
			if (err != 0) {
				return err;
			}
			stage.render();
		} catch (e) {
			Log.debug(e.message);
			throw e;
		}
		return 0;
	}

	public function dispose():Void {
		Log.debug('Disposing...');
		// if (mainLoopEvent != null) {
		//	mainLoopEvent.stop(); // Stop the main loop.
		//	mainLoopEvent = null;
		// }
		stage.dispose();
	}

	public function run(stage:IStage, ?options:AppOptions):Void {
		Log.debug('Running...');

		try {
			init(stage, options);
			// Note that this will not block!
			// mainLoopEvent = MainLoop.add(update);
			this.frameRate = Std.int(frameRate ?? 60);
			var currentTimeSec = Timer.stamp();
			lastFrameTimeSec = currentTimeSec;
			totalElapsedTimeSec = 0.0;
			var err = 0;

			var delayBetweenFramesMS = Std.int(1000.0 / this.frameRate);

			function loop():Void {
				currentTimeSec = Timer.stamp();
				deltaTimeMS = Std.int( (currentTimeSec - lastFrameTimeSec) * 1000.0);
				err = update(deltaTimeMS);
				if (quitFlag || (err != 0)) {
					dispose();
					return;
				}
				lastFrameTimeSec = currentTimeSec;
				// schedule the next update
				Timer.delay(loop, delayBetweenFramesMS);
			}

			// kick it off
			loop();
			// dispose();

			if (err != 0) {
				Log.debug("Error: " + err);
			}
		} catch (e) {
			// something failed with our init or adding our update to the main loop
			// this is not a result of a failure in update!
			// if (mainLoopEvent != null) {
			//	mainLoopEvent.stop();
			//	mainLoopEvent = null;
			// }
			Log.debug(e.message);
			// try to dispose?
			dispose();
		}
	}

	public function quit():Void {
		quitFlag = true;
	}
}