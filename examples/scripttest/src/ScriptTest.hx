package;

import haxe.Constraints.Function;
import hxcore.util.FPSCounter;
import hxcore.scripting.ScriptLoader;
import hxcore.ecs.Entity;
import hxcore.ecs.EntityManager;
import hxcore.logging.Log;

@:expose
@:keep
class ScriptTest {
	private var quitFlag:Bool = false;

	public function new(scriptDirectory:String = null, scriptSourceDirectory:String = null, enableScriptWatcher:Bool = false) {
		Log.info('Hello, World!');

		#if scriptable
		if (scriptDirectory != null && scriptDirectory.length > 0) {
			ScriptLoader.setScriptDirectory(scriptDirectory);

			// optionally start the script watcher.  This will watch for changes to .cppia files and reload them.
			if (enableScriptWatcher) {
				ScriptLoader.enableScriptWatcher();
			}
		}

		if (scriptSourceDirectory != null && scriptSourceDirectory.length > 0) {
			// a script source directory was provided, enable the watcher and hot compile
			ScriptLoader.enableHotCompile(scriptSourceDirectory);
		}
		#end
	}

	public function init() {
		// Create a new entity
		var entity = EntityManager.createEntity();
		if (entity == null) {
			Log.error("Failed to create entity");
			return;
		}
		// Attach the script to the entity
		entity.attachScript("Test", (scriptInstance) -> {
			if (scriptInstance == null) {
				Log.warn("Failed to create script: Test");
			}
		}, (scriptInstance) -> {
			if (scriptInstance == null) {
				Log.warn("Failed to load script: Test");
			}
		});
	}

	public function quit() {
		quitFlag = true;
	}

	public function update(deltaTimeMS:Float):Bool {
		FPSCounter.addFrame(deltaTimeMS);

		if (!quitFlag) {
			EntityManager.update(deltaTimeMS);
		}

		return quitFlag || false;
	}

	public function fixedUpdate(frameDurationMS:Float):Bool {
		if (!quitFlag) {
			EntityManager.fixedUpdate(frameDurationMS);
		}

		return quitFlag || false;
	}

	public function destroy() {
		// should already be set, but just to be safe
		quitFlag = true;

		EntityManager.clear();

		// shut down the script loader
		ScriptLoader.dispose();
	}

	/*
	public function run() {
		init();
		var updateHandler = new hxcore.util.UpdateHandler();
		updateHandler.run({
			onUpdateCallback: update,
			updateRateFPS: 60,
			onFixedUpdateCallback: fixedUpdate,
			fixedUpdateRateFPS: 24,
			onQuitCallback: destroy
		});
	}
	*/


	static function main() {
		Log.info('Hello, World!');
		var scriptDirectory = "";
		var scriptSourceDirectory = null;
		var enableScriptWatcher = false;

		function showUsage() {
			Log.info('Usage: scripttest [options]');
			Log.info('Options:');
			Log.info('  --help, -?, -h          Show this help message');
			Log.info('  --version, -v           Show the version number');
			Log.info('  --scriptdir,  --scripts, -s <output dir> Set the script directory (.cppia files, "./scripts" by default)');
			Log.info('  --sourcedir, -srcdir, -src, <source dir> Set the script source directory (.hx source files location.  Setting this will also enable the script compiler watcher)');
			Log.info('  --watch, --hotreload, --enablescriptwatcher,-w, -hr          Enable the script watcher (disabled by default)');
			Log.info('  --nowatch, --nohotreload, --disablescriptwatcher,-nw, -nhr    Disable the script watcher');
			return;
		}

		// get the script directory from the command line, if specified
		var args = Sys.args();
		var currentArgIndex = 0;
		while (currentArgIndex < args.length) {
			var arg = args[currentArgIndex];
			arg = arg.toLowerCase();
			arg = StringTools.trim(arg);
			Log.debug('Processing arg: ' + arg);
			switch (arg) {
				case "--help", "-?", "-h":
					showUsage();
					return;
				case "--version", "-v":
					Log.info('ScriptTest version 0.0.1');
					return;
				case "--scriptdir", "--scripts", "-s":
					if (currentArgIndex + 1 >= args.length) {
						Log.error('Error: ${arg} requires a directory argument');
						return;
					}
					scriptDirectory = args[currentArgIndex + 1];
					// skip the next arg since we've already processed it
					currentArgIndex++;
				case "--sourcedir", "-srcdir", "-src":
					if (currentArgIndex + 1 >= args.length) {
						Log.error('Error: ${arg} requires a directory argument');
						return;
					}
					scriptSourceDirectory = args[currentArgIndex + 1];
					// skip the next arg since we've already processed it
					currentArgIndex++;
				case "--watch", "--hotreload", "--enablescriptwatcher", "-w", "-hr":
					enableScriptWatcher = true;
				case "--nowatch", "--nohotreload", "--disablescriptwatcher", "-nw", "-nhr":
					enableScriptWatcher = false;
				default:
					Log.error('Error: Unrecognized argument: ${arg}');
					showUsage();
					return;
			}

			currentArgIndex++;
		}

		if (scriptDirectory.length == 0) {
			// check env variable
			scriptDirectory = Sys.getEnv("SCRIPT_DIR");
		}
		if (scriptDirectory.length == 0) {
			// default to "scripts"
			scriptDirectory = "scripts";
		}
		var scriptTest = new ScriptTest(scriptDirectory, scriptSourceDirectory, enableScriptWatcher);

		scriptTest.init();

		// start the update loop
		var updateHandler = new hxcore.util.UpdateHandler();
		updateHandler.run({
			onUpdateCallback: scriptTest.update,
			updateRateFPS: 60,
			onFixedUpdateCallback: scriptTest.fixedUpdate,
			fixedUpdateRateFPS: 24,
			onQuitCallback: scriptTest.destroy
		});
	}
}
