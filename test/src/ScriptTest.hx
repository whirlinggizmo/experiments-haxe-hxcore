package;

import hxcore.scripting.ScriptLoader;
import hxcore.ecs.Entity;
import hxcore.logging.Log;

@:expose
@:keep
@:build(HaxeCBridge.expose())
class ScriptTest {
	var entity:Entity;

	public function new(scriptDirectory:String = null, scriptSourceDirectory:String = null) {
		Log.info('Hello, World!');

		#if scriptable
		if (scriptDirectory != null && scriptDirectory.length > 0) {
			ScriptLoader.setScriptDirectory(scriptDirectory);
			
			// optionally start the script watcher.  This will watch for changes to .cppia files and reload them. 
			ScriptLoader.enableScriptWatcher();
		}

		if (scriptSourceDirectory != null && scriptSourceDirectory.length > 0) {
			// a script source directory was provided, enable the watcher and hot compile
			ScriptLoader.enableHotCompile(scriptSourceDirectory);
		} 
		#end

		// Create a new entity
		entity = new Entity();

		// Attach the script to the entity
		entity.attachScript("Test", (scriptInstance) -> {
			// Emit an "attack" event
			entity.dispatchEvent("attack", {damage: 50});
		});
	}

	var lastUpdateTime = haxe.Timer.stamp();

	public function update() {
		var currentTime = haxe.Timer.stamp();
		var deltaTime = currentTime - lastUpdateTime;
		lastUpdateTime = currentTime;
		tick(deltaTime);
	}

	public function tick(deltaTime:Float) {
		if (entity != null) {
			entity.dispatchEvent("attack", {damage: Math.random() * 100});
		}
	}

	public function destroy() {
		if (entity != null) {
			Log.debug("Destroying entity");
			entity.dispose();
			entity = null;
		}

		// shut down the script loader
		ScriptLoader.dispose();

		Log.info('Goodbye, World!');
	}

	/**
	 * appMain()
	 * Intended to be called at entry (assuming this is an executable).  Using this as a library, this wouldn't be called.
	 */
	static function appMain() {
		Log.debug('Running ScriptTest:main() as app');
		var scriptDirectory = "";
		var scriptSourceDirectory = null;

		// get the script directory from the command line, if specified
		var args = Sys.args();
		for (i in 0...args.length) {
			var arg = args[i];
			arg = arg.toLowerCase();
			arg = StringTools.trim(arg);
			if (arg == "--scriptdir" || arg == "--scripts" || arg == "-out" || arg == "-o" || arg == "-outdir") {
				if (i + 1 >= args.length) {
					Log.error('Error: ${arg} requires a directory argument');
					return;
				}
				scriptDirectory = args[i + 1];
			}

			if (arg == "--sourcedir" || arg == "--source" || arg == "-src" || arg == "-s") {
				if (i + 1 >= args.length) {
					Log.error('Error: ${arg} requires a directory argument');
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

		var scriptTest = new ScriptTest(scriptDirectory, scriptSourceDirectory);

		// set up a ticking update loop
		var timer = new haxe.Timer(Std.int(1000 / 24));
		var lastTime = haxe.Timer.stamp();
		timer.run = function() {
			var currentTime = haxe.Timer.stamp();
			var deltaTime = currentTime - lastTime;
			lastTime = currentTime;
			scriptTest.tick(deltaTime);
		};
	} 

	static function libMain() {
		Log.debug('Running ScriptTest:main() as lib');
	}

	public static function main() {
		#if (static_link || dll_link)
		return libMain();
		#else
		return appMain();
		#end
	}

	/**
	 * libTest()
	 * Testing using this as a lib, not calling main()
	 */
	public static function libTest() {
		new ScriptTest('scripts', 'scripts/src');
	}
}
