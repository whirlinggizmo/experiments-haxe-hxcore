typedef ScriptContext = Dynamic;

function create() {
	return {};
}
/*
	@:structInit
	class ScriptContext {
	private var kvMap:Map<String, Dynamic> = new Map();

	public function new() {}

	public function get(key:String):Dynamic {
		return this.kvMap.get(key);
	}

	public function set(key:String, value:Dynamic):Void {
		this.kvMap.set(key, value);
	}

	public function remove(key:String):Void {
		this.kvMap.remove(key);
	}

	public function exists(key:String):Bool {
		return this.kvMap.exists(key);
	}

	public function keys():Iterator<String> {
		return this.kvMap.keys();
	}
	}
 */
