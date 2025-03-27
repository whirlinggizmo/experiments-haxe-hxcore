package hxcore.util;

class FPSCounter {
	static private var averageFPS:Float = 0.0;
	static private var frameTimes:Array<Float> = [];
	static private var sampledFrameTime:Float = 0.0;
	static private var maxSamples = 60; // Customize: Number of frames to average over
	static private var nextIndex = 0;
	static private var count = 0;

	static public function addFrame(deltaTimeMS:Float) {
		if (count < maxSamples) {
			frameTimes.push(deltaTimeMS);
			sampledFrameTime += deltaTimeMS;
			count++;
		} else {
			// Overwrite oldest sample in circular fashion
			sampledFrameTime -= frameTimes[nextIndex];
			frameTimes[nextIndex] = deltaTimeMS;
			sampledFrameTime += deltaTimeMS;
		}

		nextIndex = (nextIndex + 1) % maxSamples;
		averageFPS = MathUtils.round(1000.0 / (sampledFrameTime / count), 1);
	}

	static public function FPS():Float {
		return averageFPS;
	}

	static public function reset() {
		averageFPS = 0.0;
		sampledFrameTime = 0.0;
		frameTimes = [];
		nextIndex = 0;
		count = 0;
	}
}
