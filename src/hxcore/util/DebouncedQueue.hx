package hxcore.util;

class DebouncedQueue<T> {
	var windowMs:Int;
	var lastPushAt:Null<Int>;
	var items:Map<String, T>;
	var keyFn:T->String;

	public function new(windowMs:Int, ?keyFn:T->String) {
		this.windowMs = windowMs;
		this.lastPushAt = null;
		this.items = new Map();
		this.keyFn = keyFn != null ? keyFn : (item:T) -> Std.string(item);
	}

	public function push(item:T, nowMs:Int):Void {
		var key = keyFn(item);
		items.set(key, item);
		lastPushAt = nowMs;
	}

	public function flush(nowMs:Int):Array<T> {
		if (lastPushAt == null) {
			return [];
		}
		if (nowMs - lastPushAt < windowMs) {
			return [];
		}
		var out:Array<T> = [];
		for (item in items) {
			out.push(item);
		}
		items.clear();
		lastPushAt = null;
		return out;
	}

	public function size():Int {
		var count = 0;
		for (_ in items) count++;
		return count;
	}
}
