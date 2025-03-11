package tests.cppia;

import haxe.io.Path;
import core.scripting.ScriptLoader;
import core.ecs.Entity;


@:expose
@:keep
class ScriptTest {
	var entity:Entity;

	public function new() {
		trace('Hello, World!');

		var scriptDirectory = "";
		var scriptSourceDirectory = "";

		// get the script directory from the command line, if specified
		var args = Sys.args();
		for ( i in 0...args.length ) {
			var arg = args[i];
			arg = arg.toLowerCase();
			arg = StringTools.trim(arg);
			if (arg == "--scriptdir" || arg == "--scripts" || arg == "-out" || arg == "-o" || arg == "-outdir") {
				if (i + 1 >= args.length) {
					trace("Error: --scripts requires a directory argument");
					return;
				}
				scriptDirectory = args[i + 1];
			}

			if (arg == "--sourcedir" || arg == "--source" || arg == "-src" || arg == "-s") {
				if (i + 1 >= args.length) {
					trace("Error: --source requires a directory argument");
					return;
				}
				scriptSourceDirectory = args[i + 1];
			}
		}

		if (scriptDirectory.length == 0) {
			// check env variable
			scriptDirectory = Sys.getEnv("SCRIPT_DIR");
		}

		if (scriptDirectory.length == 0) {
			// default to "scripts"
			scriptDirectory = "scripts";
		}

		Log.info("Setting script directory to: " + scriptDirectory);
		ScriptLoader.scriptDirectory = scriptDirectory;

		#if scriptable
		if (scriptSourceDirectory.length == 0) {
			// check env variable
			scriptSourceDirectory = Sys.getEnv("SCRIPT_SRC_DIR");
		}

		if (scriptSourceDirectory.length == 0) {
			// default to "scripts"
			scriptSourceDirectory = Path.join([Path.directory(Sys.programPath()), "src"]); // default to src in the same directory as the executable
		}

		Log.info("Setting script source (.hx) directory to: " + scriptSourceDirectory);
		ScriptLoader.scriptSourceDirectory = scriptSourceDirectory;
		#end

		// Create a new entity
		entity = new Entity();

		// Attach the script to the entity
		entity.attachScript("Test", (scriptInstance) -> {
			// Emit an "attack" event
			entity.dispatchEvent("attack", {damage: 50});
		});

		// set up a tick loop
		var timer = new haxe.Timer(Std.int(1000 / 24));
		var lastTime = haxe.Timer.stamp();
		timer.run = function() {
			var currentTime = haxe.Timer.stamp();
			var deltaTime = currentTime - lastTime;
			lastTime = currentTime;
			tick(deltaTime);
		};
	}

	public function tick(deltaTime:Float) {
		// trace('tick', deltaTime);
		if (entity != null) {
			entity.dispatchEvent("attack", {damage: Math.random() * 100});
		}
	}

	public static function ready() {
		new ScriptTest();
	}

	public static function main() {
		// do whatever static init you need before ready
		ready();
	}
}
