package hxcore.scripting;

import hxcore.util.DebouncedQueue;

class ScriptChangeCoalescer {
	var queue:DebouncedQueue<String>;

	public function new(debounceMs:Int) {
		queue = new DebouncedQueue<String>(debounceMs, (s) -> s);
	}

	public function push(path:String, nowMs:Int):Void {
		queue.push(path, nowMs);
	}

	public function flush(nowMs:Int):Array<String> {
		return queue.flush(nowMs);
	}
}
