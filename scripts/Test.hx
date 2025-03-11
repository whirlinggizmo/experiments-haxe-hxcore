class Test extends Script {
	var thing:String;

	function onAttack(args) {
		log('Attack received with damage: ${Std.string(args.damage)}');
	} 

	override function onLoad() {
		log("Test.load");
		thing = "HELLO";
		addEventListener("attack", "onAttack");
	}

	override function onReload() {
		log("Test.reload");
		log(ctx);
		thing = ctx.stashed.thing;
		log("after reload: " + thing);	
	}

	function onUpdate(deltaTimeMS:Float) {
		log("Test.updated");
	}

	override function onUnload() {
		log("Test.unload");
		ctx.stashed = {
			thing: "NICE"
		}
	}
}
