
// The scripts directory is added to the class path, so no package required 
//package;

import hxcore.util.FPSCounter;

class Test extends Script {
	var thing:String;

	function onAttack(args) {
		log('Attack received with damage: ${Std.string(args.damage)}');
	} 

	override function onLoad() {
		log("Test.onLoad");
		thing = "HELLO";
		addEventListener("attack", onAttack);
	}

	override function onReload() {
		log("Test.onReload");
		addEventListener("attack", onAttack);

		log(ctx);
		thing = ctx.stashed.thing;
		log("after reload: " + thing);	
	}

	override function onUpdate(deltaTimeMS:Float) {
		log('Test.onUpdate: ${Math.round(deltaTimeMS)} ms, FPS: ${FPSCounter.FPS()}');
	}

	override function onUnload() {
		log("Test.onUnload");
		ctx.stashed = {
			thing: "NICE"
		}
	}
}
