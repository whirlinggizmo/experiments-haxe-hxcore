// The scripts directory is added to the class path, so no package required 
//package;

import hxcore.util.FPSCounter;

class Test extends Script {
	var thing:String;

	function onAttack(args) {
		log('Attack received with damagffe: ${Std.string(args.damage)}');
	} 


	override function onUpdate(deltaTimeMS:Float) {
		log('Updated: (${Math.round(deltaTimeMS)} ms, ${FPSCounter.FPS()} fps)');
	}

	//override function onFixedUpdate(frameDurationMS:Float) {
	//	log('FixedUpdate: ($frameDurationMS ms)');
	//}

	override function onLoad() {
		log("Test.load");
		thing = "HELLO";
		addEventListener("attack", onAttack);
	}

	override function onReload() {
		log("Test.reload");
		addEventListener("attack", onAttack);

		log(ctx);
		thing = ctx.stashed.thing;
		log("after reload: " + thing);	
	}

	override function onUnload() {
		log("Test.unload");
		ctx.stashed = {
			thing: "NICE"
		}
	}
}
