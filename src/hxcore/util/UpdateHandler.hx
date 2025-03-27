package hxcore.util;

#if js
import js.Syntax;
import js.Browser;
#end

typedef UpdateCallback = (deltaTimeMS:Float) -> Bool;
typedef FixedUpdateCallback = (deltaTimeMS:Float) -> Bool;
typedef QuitCallback = () -> Void;

typedef UpdateOptions = {
	?updateRateFPS:Int,
	?onUpdateCallback:UpdateCallback,
	?fixedUpdateRateFPS:Int,
	?onFixedUpdateCallback:FixedUpdateCallback,
	?onQuitCallback:QuitCallback
};

class UpdateHandler {
	var onUpdateCallback:UpdateCallback;
	var onFixedUpdateCallback:FixedUpdateCallback;
	var onQuitCallback:QuitCallback;
	var quitFlag:Bool;
	var tickTimer:haxe.Timer;
	var inTick:Bool;
	var fixedUpdateRateFPS:Int;
	var updateRateFPS:Int;
	var frameDuration:Float;
	var frameDurationMS:Float;
	var lastUpdateTime:Float;
	var lastFixedUpdateTime:Float;
	var fixedUpdateTimeAccumulator:Float;

	public function new() {}

	public function dispose():Void {
		if (tickTimer != null) {
			tickTimer.stop();
			tickTimer = null;
		}
		quitFlag = true;

		onFixedUpdateCallback = null;
		onUpdateCallback = null;
		onQuitCallback = null;
	}

	public function quit():Void {
		quitFlag = true;
	}

	/**
	 * Called once per update tick. Handles both fixed and variable updates.
	 * @return true if quitFlag was set during this tick
	 */
	private function tick():Bool {
		if (quitFlag) {
			return true;
		}
		// prevent reentrancy
		if (inTick) {
			return false;
		}
		inTick = true;

		var currentTime = haxe.Timer.stamp();

		// Fixed update
		if (onFixedUpdateCallback != null && !quitFlag) {
			var fixedDelta = currentTime - lastFixedUpdateTime;
			if (fixedDelta > 0.25)
				fixedDelta = 0.25;
			fixedUpdateTimeAccumulator += fixedDelta;
			lastFixedUpdateTime = currentTime;

			while (fixedUpdateTimeAccumulator >= frameDuration && !quitFlag) {
				quitFlag = quitFlag || onFixedUpdateCallback(frameDurationMS);
				fixedUpdateTimeAccumulator -= frameDuration;
			}
		}

		// Variable update
		if (onUpdateCallback != null && !quitFlag) {
			var updateDelta = currentTime - lastUpdateTime;
			lastUpdateTime = currentTime;
			quitFlag = quitFlag || onUpdateCallback(updateDelta * 1000.0);
		}

		inTick = false;

		return quitFlag;
	}

	public function run(options:UpdateOptions):Void {
		dispose();

		onUpdateCallback = options.onUpdateCallback;
		onFixedUpdateCallback = options.onFixedUpdateCallback;
		onQuitCallback = options.onQuitCallback;
		updateRateFPS = options.updateRateFPS ?? 60;
		fixedUpdateRateFPS = options.fixedUpdateRateFPS ?? 24;
		frameDuration = 1.0 / fixedUpdateRateFPS;
		frameDurationMS = frameDuration * 1000.0;
		fixedUpdateTimeAccumulator = 0.0;
		lastUpdateTime = haxe.Timer.stamp();
		lastFixedUpdateTime = lastUpdateTime;
		quitFlag = false;

		#if (js || emscripten) // js or emscripten should use "requestAnimationFrame" instead of "setInterval" (which is what haxe.Timer will generate)
        // for js/emscripten targets
		function animationFrameTick(e):Void {
			quitFlag = quitFlag || tick();

			if (quitFlag) {
				if (onQuitCallback != null) {
					onQuitCallback();
				}
				Log.info('Goodbye, World!');
			} else {
				js.Browser.window.requestAnimationFrame(animationFrameTick);
			}
		}
		js.Browser.window.requestAnimationFrame(animationFrameTick);
		#else
		tickTimer = new haxe.Timer(Std.int(1000.0 / updateRateFPS));
		tickTimer.run = function() {
			quitFlag = quitFlag || tick();
			if (quitFlag) {
				tickTimer.stop();
				tickTimer = null;

				if (onQuitCallback != null) {
					onQuitCallback();
				}

				Log.info('Goodbye, World!');
			}
		};
		#end
	}
}
