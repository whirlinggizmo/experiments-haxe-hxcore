package;

import hxcore.util.FPSCounter;
import hxcore.scripting.ScriptLoader;
import hxcore.ecs.Entity;
import hxcore.ecs.EntityManager;
import hxcore.logging.Log;

@:expose
@:keep
class ScriptTest {
	private var quitFlag:Bool = false;

	public function new() {}

	public function init(scriptDirectory:String = null, scriptSourceDirectory:String = null, enableHotReload:Bool = false) {
		Log.info('Hello, World!');

		Log.debug('CWD: ' + Sys.getCwd() );


		Log.debug('scriptDirectory: ' + scriptDirectory);
		Log.debug('scriptSourceDirectory: ' + scriptSourceDirectory);
		Log.debug('enableHotReload: ' + enableHotReload);

		if (scriptDirectory != null && scriptDirectory.length > 0) {
			ScriptLoader.enableExternalScripts(scriptDirectory);
		}

		if (enableHotReload) {
			if (scriptDirectory == null || scriptDirectory.length == 0) {
				Log.error('Error: hot reload requires the script directory (for the compiled scripts)');
				return;
			}
			ScriptLoader.enableHotReload();
		}

		if (scriptSourceDirectory != null && scriptSourceDirectory.length > 0) {
			if (scriptDirectory == null || scriptDirectory.length == 0) {
				Log.error('Error: hot compile requires the script directory (for the compiled scripts)');
				return;
			}
			ScriptLoader.enableHotCompile(scriptSourceDirectory);
		}
	}

	public function loadTest() {
		// Create a new entity
		var entity = EntityManager.createEntity();
		if (entity == null) {
			Log.error("Failed to create entity");
			return;
		}
		// Attach the script to the entity
		entity.attachScript("scripts.Test", (scriptInstance) -> {
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
		var scriptDirectory = null;
		var scriptSourceDirectory = null;
		var enableHotReload = false;

		function showUsage() {
			Log.info('Usage: scripttest [options]');
			Log.info('Options:');
			Log.info('  --help, -?, -h          Show this help message');
			Log.info('  --version, -v           Show the version number');
			Log.info('  --scriptdir,  --scripts, -s <output dir> Set the script directory (.cppia files).  Setting this will enable external script loading)');
			Log.info('  --sourcedir, -srcdir, -src, <source dir> Set the script source directory (.hx source files).  Setting this will enable hot compile)');
			Log.info('  --watch, --hotreload, -w, -hr          Enable the hot reload script watcher');
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
					enableHotReload = true;
				default:
					Log.error('Error: Unrecognized argument: ${arg}');
					showUsage();
					return;
			}

			currentArgIndex++;
		}

		/*
		if (scriptDirectory.length == 0) {
			// check env variable
			scriptDirectory = Sys.getEnv("SCRIPTDIR");
		}
		*/
	
		var scriptTest = new ScriptTest();
		scriptTest.init(scriptDirectory, scriptSourceDirectory, enableHotReload);

		// run the script test
		scriptTest.loadTest();

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
