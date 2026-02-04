package tests.scripting;

import hxcore.scripting.Script;

class FakeScriptTwo extends Script {
	public static var loadCount:Int = 0;
	public static var updateCount:Int = 0;

	override public function onLoad():Void {
		loadCount++;
	}

	override public function onUpdate(deltaTimeMS:Float):Void {
		updateCount++;
	}
}
