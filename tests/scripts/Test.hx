package scripts;

import hxcore.scripting.Script;

@:keep
class Test extends Script {
	public function new() {
		super();
	}

	public function getMarker():String {
		return "internal";
	}
}
