package;

import core.scripting.Script;
import haxe.io.Path;
import core.scripting.ScriptLoader;
import core.ecs.Entity;
import core.logging.Log;

@:expose
@:keep
class ScriptTest {
	var entity:Entity;

	public function new() {
		trace('Hello, World!');

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

	public static function main() {
		var scriptDirectory = "";
		var scriptSourceDirectory = "";
		var hotCompileEnabled = false;
		var hotReloadEnabled = false;

		#if (scriptable)
		// get the script directory from the command line, if specified
		var args = Sys.args();
		for (i in 0...args.length) {
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
			if (arg == "--hotreload" || arg == "--hot_reload" || arg == "-hr" ) {
				hotReloadEnabled = true;
			}
		}

		if (scriptDirectory.length == 0) {
			// check env variable
			scriptDirectory = Sys.getEnv("SCRIPT_DIR");
		}

		if (scriptDirectory.length == 0) {
			// default to "scripts/gen" in the parent directory (dev)
			scriptDirectory = Path.join([Path.directory(Sys.programPath()), "../scripts/gen"]);
		}

		scriptDirectory = Path.normalize(scriptDirectory);
		Log.info("Setting script directory to: " + scriptDirectory);
		ScriptLoader.setScriptDirectory(scriptDirectory);

		// enable hot reload.  This will start a filewatcher on the script (.cppia) files
		if (hotReloadEnabled) {
			Log.info("Enabling hot reload");
			ScriptLoader.enableHotReload();
		} else {
			Log.info("Hot reload disabled");
		}

		// script compiler
		// get the script source directory from the command line, if specified
		var args = Sys.args();
		for (i in 0...args.length) {
			var arg = args[i];
			arg = arg.toLowerCase();
			arg = StringTools.trim(arg);

			if (arg == "--sourcedir" || arg == "--source" || arg == "-src" || arg == "-s") {
				if (i + 1 >= args.length) {
					trace("Error: --source requires a directory argument");
					return;
				}
				scriptSourceDirectory = args[i + 1];
			}
			if (arg == "--hotcompile" || arg == "--hot_compile" || arg == "-hc") {
				hotCompileEnabled = true;
			}
		}
		if (hotCompileEnabled) {
			if (scriptSourceDirectory.length == 0) {
				// check env variable
				scriptSourceDirectory = Sys.getEnv("SCRIPT_SRC_DIR");
			}

			if (scriptSourceDirectory.length == 0) {
				// default to "scripts/src"
				scriptSourceDirectory = Path.join([Path.directory(Sys.programPath()), "../scripts/src"]);
			}
			scriptSourceDirectory = Path.normalize(scriptSourceDirectory);
			Log.warn("Setting script source (.hx) directory to: " + scriptSourceDirectory);
			Log.info("Enabling hot compile");
			ScriptLoader.enableHotCompile(scriptSourceDirectory);
		} else {
			Log.info("Hot compile disabled");
		}
		
		#end // (scriptable)

		new ScriptTest();
	}
}
