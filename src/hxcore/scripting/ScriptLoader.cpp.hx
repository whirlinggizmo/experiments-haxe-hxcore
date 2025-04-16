// src/hxcore/scripting/ScriptLoader.cpp.hx
package hxcore.scripting;

import hxcore.logging.Log;
import hxcore.util.TypeUtils;
import hxcore.scripting.Script;
import haxe.io.Path;
import hxcore.util.PathUtils;
#if sys
import hxcore.scripting.ScriptCompiler;
import hxcore.io.FileWatcher;
import hxcore.io.FileWatcher.FileEvent;
import sys.FileSystem;
#if scriptable
import cpp.cppia.Module;
#end
#end
typedef LoadedCallback = (scriptName:String, scriptInfo:ScriptInfo) -> Void;

typedef ScriptInfo = {
	var ?className:String;
	var ?script:Script;
	var ?loadedCallback:LoadedCallback;
	var ?isExternal:Bool;
	var ?sourcePath:String;
}

class ScriptLoader {
	private static var scriptCache:Map<String, ScriptInfo> = new Map<String, ScriptInfo>();
	private static var scriptDirectory:String;
	private static var scriptSourceDirectory:String;
	private static var hotReloadEnabled:Bool = false;
	private static var hotCompileEnabled:Bool = false;
	private static var externalScriptsEnabled:Bool = false;
	private static var internalScriptNamespace:String = "scripts";

	#if sys
	private static var haxeSourceFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	private static var cppiaFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	#end

	private static function setScriptDirectory(scriptDirectory:String):Void {
		if (!Path.isAbsolute(scriptDirectory)) {
			scriptDirectory = Path.join([Path.directory(Sys.programPath()), scriptDirectory]);
		}
		ScriptLoader.scriptDirectory = scriptDirectory;
	}

	public static function enableExternalScripts(scriptDirectory:String):Void {
		#if (!sys || !scriptable)
		Log.warn("External script loading not available on this platform (requires sys, scriptable)");
		return;
		#end
		if (!Path.isAbsolute(scriptDirectory)) {
			scriptDirectory = Path.join([Path.directory(Sys.programPath()), scriptDirectory]);
		}
		ScriptLoader.scriptDirectory = scriptDirectory;
		externalScriptsEnabled = true;
	}

	public static function enableHotReload():Void {
		#if (sys && scriptable)
		hotReloadEnabled = true;
		#else
		Log.warn("Hot reload not available on this platform (requires sys, scriptable)");
		#end
	}

	public static function enableHotCompile(scriptSourceDirectory:String):Void {
		#if sys
		if (!Path.isAbsolute(scriptSourceDirectory)) {
			scriptSourceDirectory = Path.join([Path.directory(Sys.programPath()), scriptSourceDirectory]);
		}
		ScriptLoader.scriptSourceDirectory = scriptSourceDirectory;
		hotCompileEnabled = true;
		#else
		Log.warn("Hot compile not available on this platform (requires sys)");
		#end
	}

	private static function getClassName(scriptDirectory:String, scriptName:String):String {
		// the scriptName is the class name of the script, so replace any '.' with '/'
		var parts:Array<String> = scriptName.split('.');
		var className:String = parts[parts.length - 1];
		// Log.debug("className: " + className);
		return className;
	}

	private static function getClassPath(scriptDirectory:String, scriptName:String):String {
		// the scriptName is the class name of the script, so replace any '.' with '/'
		var parts:Array<String> = scriptName.split('.');
		// prepend the script directory
		parts.unshift(scriptDirectory);
		var classPath = Path.join(parts.slice(0, parts.length - 1));
		if (classPath.length == 0) {
			classPath = ".";
		}
		// Log.debug("classPath: " + classPath);

		return classPath;
	}

	/*
		private static function getProgramBasePath():String {
			// Get the full path to the program
			var programBasePath = FileSystem.fullPath(Sys.programPath());

			// If the program path points to a file (e.g., executable), get the directory by manipulating the string
			if (!FileSystem.isDirectory(programBasePath)) {
				programBasePath = programBasePath.split("/").slice(0, -1).join("/");
			}

			return programBasePath;
		}
	 */
	/**
	 * createHotReloadWatcher()
	 * Sets up a file watcher for the script file (.cppia) and calls the onChanged callback when the file changes
	 * @param scriptDirectory : The root directory of the scripts (.cppia)
	 * @param scriptName : The script (class) to watch.  e.g., "Test" or "mypackage.Test"
	 * @param onChanged : The callback to call when the file changes. String->Void
	 */
	private static function createHotReloadWatcher(scriptDirectory:String, scriptName:String, onChanged:String->Void) {
		if (!externalScriptsEnabled) {
			Log.warn("External scripts not enabled");
			return;
		}
		if (!hotReloadEnabled) {
			Log.warn("Hot reload not enabled");
			return;
		}
		#if (sys && scriptable)
		if (scriptName.length == 0) {
			Log.warn("No script name specified");
			return;
		}

		if (scriptDirectory.length == 0) {
			Log.warn("No script directory specified");
			return;
		}

		if (!Path.isAbsolute(scriptDirectory)) {
			scriptDirectory = Path.join([Path.directory(Sys.programPath()), scriptDirectory]);
		}

		scriptDirectory = Path.normalize(scriptDirectory);

		Log.info("Path for compiled script files(.cppia) files is: " + scriptDirectory);

		// remove any existing cppia file watchers
		if (cppiaFileWatchers.exists(scriptName)) {
			cppiaFileWatchers[scriptName].stop();
			cppiaFileWatchers.remove(scriptName);
		}

		// break the scriptName into the package name and class name
		var className = getClassName(scriptDirectory, scriptName);

		var scriptCppiaFileFilter = className;

		// adjust the regexp to match the script name
		scriptCppiaFileFilter = StringTools.replace(scriptCppiaFileFilter, ".", "/");
		scriptCppiaFileFilter = StringTools.replace(scriptCppiaFileFilter, "/", "\\/");
		scriptCppiaFileFilter = StringTools.replace(scriptCppiaFileFilter, "*", ".*");
		scriptCppiaFileFilter = StringTools.replace(scriptCppiaFileFilter, "?", "\\?");

		// add the extension after transforming '.' to '/'
		scriptCppiaFileFilter = scriptCppiaFileFilter + "\\.cppia";

		// make it an exact match
		scriptCppiaFileFilter = "^" + scriptCppiaFileFilter + "$";

		var scriptCppiaPath = getClassPath(scriptDirectory, scriptName);
		// scriptCppiaPath = Path.join([scriptDirectory, scriptCppiaPath]); // programBasePath + "/../" + scriptDirectory;
		// scriptCppiaPath = Path.normalize(scriptCppiaPath);

		var cppiaFileWatcher = new FileWatcher(scriptCppiaPath, scriptCppiaFileFilter, (filename:String, event:FileEvent) -> {
			// if (filename != scriptCppiaFile) {
			//	Log.warn("Script file different path than expected!: " + filename + " != " + scriptCppiaFile);
			//	return;
			// }

			// TODO: Handle the case where the file is deleted
			if (event == FileEvent.Removed) {
				Log.warn("Script file deleted " + filename);
				onChanged(filename);
				return;
			}

			if (event == FileEvent.Added) {
				// Log.warn("Script file added, ignoring: " + filename);
				onChanged(filename);
				return;
			}

			Log.info("Script file changed: " + filename);

			onChanged(filename);
		});

		cppiaFileWatcher.start();
		cppiaFileWatchers.set(scriptName, cppiaFileWatcher);
		#else
		Log.warn("HotReloadWatcher not created, requires sys, -D scriptable");
		#end
	}

	/**
	 * Create a FileWatcher to recompile script source file changes (.hx -> .cppia)
	 * @param scriptDirectory 
	 * @param scriptName 
	 * @param onLoaded 
	 */
	private static function createHotCompileWatcher(scriptDirectory:String, scriptName:String, scriptChangedCallback:String->Void) {
		if (!hotCompileEnabled) {
			Log.warn("Hot compile not enabled");
			return;
		}

		#if (sys && scriptable)
		//
		// Create a FileWatcher to monitor the script file (the .hx file)
		//

		if (scriptName.length == 0) {
			Log.warn("No script name specified");
			return;
		}

		if (scriptDirectory.length == 0) {
			Log.warn("No script directory specified");
			return;
		}

		if (!Path.isAbsolute(scriptDirectory)) {
			scriptDirectory = Path.join([Path.directory(Sys.programPath()), scriptDirectory]);
		}
		scriptDirectory = Path.normalize(scriptDirectory);
		Log.info("Path for script source files(.hx) files is: " + scriptSourceDirectory);

		if (haxeSourceFileWatchers.exists(scriptName)) {
			haxeSourceFileWatchers[scriptName].stop();
			haxeSourceFileWatchers.remove(scriptName);
		}

		// break the scriptName into the package name and class name
		var className = getClassName(scriptDirectory, scriptName);
		// var scriptSourceFile = className + ".hx";

		var scriptSourceFileFilter = className;

		// adjust the regexp to match the script name
		scriptSourceFileFilter = StringTools.replace(scriptSourceFileFilter, ".", "/");
		scriptSourceFileFilter = StringTools.replace(scriptSourceFileFilter, "/", "\\/");
		scriptSourceFileFilter = StringTools.replace(scriptSourceFileFilter, "*", ".*");
		scriptSourceFileFilter = StringTools.replace(scriptSourceFileFilter, "?", "\\?");

		// add the extension after transforming '.' to '/'
		scriptSourceFileFilter = scriptSourceFileFilter + "\\.hx";

		// make it an exact match
		scriptSourceFileFilter = "^" + scriptSourceFileFilter + "$";
		// Log.debug("scriptSourceFileFilter: " + scriptSourceFileFilter);

		var haxeSourceFileWatcher = new FileWatcher(scriptSourceDirectory, scriptSourceFileFilter, (filename:String, event:FileEvent) -> {
			// Log.debug("Script source file changed: " + filename);
			scriptChangedCallback(filename);
		});

		haxeSourceFileWatcher.start();
		haxeSourceFileWatchers.set(scriptName, haxeSourceFileWatcher);
		#else
		Log.warn("HotCompileWatcher not created (requires sys, -D scriptable)");
		#end
	}

	/**
	 * Try to load a script class from the script directory or fallback to compiled-in scripts.
	 * Ensures class is derived from Script, instantiates it, and sets metadata.
	 */
	private static function createScriptInstance(scriptDirectory:String, className:String):ScriptInfo {
		scriptDirectory = Path.addTrailingSlash(Path.normalize(scriptDirectory));
		var sourceFilePath = Path.normalize(Path.join([scriptDirectory, className + ".cppia"]));
		var resolvedClass:Class<Dynamic> = null;
		final scriptInfo:ScriptInfo = {className: className, sourcePath: sourceFilePath};
		#if scriptable
		try {
			if (!externalScriptsEnabled) {
				throw('External scripts not enabled, trying internal scripts instead: $className');
			}
			if (!FileSystem.exists(scriptDirectory)) {
				throw 'Script directory not found: $scriptDirectory';
			}

			if (!FileSystem.exists(sourceFilePath)) {
				throw 'Script file not found: $sourceFilePath';
			}

			final data = sys.io.File.getBytes(sourceFilePath).getData();
			if (data == null) {
				throw 'Failed to load module (bad data): $sourceFilePath';
			}

			final module = Module.fromData(data);
			module.boot();
			module.run();

			resolvedClass = module.resolveClass(className);
			if (resolvedClass == null) {
				throw 'Failed to resolve cppia class: $className';
			}
			scriptInfo.isExternal = true;
			scriptInfo.sourcePath = sourceFilePath;
		} catch (e:Dynamic) {
			Log.warn('Failed to load cppia module: $sourceFilePath\n${e.message}');
		}
		#end

		if (resolvedClass == null) {
			// we didn't find the class in the script directory (or it's disabled), try the internal scripts
			var internalClassName = internalScriptNamespace + "." + className;
			try {
				Log.debug('Trying to resolve class from built-in scripts: $internalClassName');
				resolvedClass = Type.resolveClass(internalClassName);
				if (resolvedClass == null) {
					throw 'Failed to resolve class from built-in scripts: $internalClassName';
				}
				scriptInfo.isExternal = false;
				scriptInfo.sourcePath = internalClassName;
			} catch (e:Dynamic) {
				Log.error('Failed to resolve built-in class: $internalClassName\n${e.message}');
				return null;
			}
		}

		if (!TypeUtils.isDerivedFrom(resolvedClass, Script)) {
			Log.error('Class $className is not derived from Script');
			return null;
		}

		final instance = Type.createInstance(resolvedClass, []);
		if (instance == null) {
			Log.error('Failed to create instance of class: $className');
			return null;
		}

		scriptInfo.script = cast instance;
		scriptInfo.className = className;

		// set some values on the script itself
		scriptInfo.script.scriptName = className;
		scriptInfo.script.scriptDirectory = scriptInfo.sourcePath;
		return scriptInfo;
	}

	public static function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);
		if (cachedScriptInfo == null) {
			Log.warn("Unable to reload script that hasn't already been loaded: " + scriptName);
			return;
		}

		var scriptInfo = createScriptInstance(scriptDirectory, scriptName);
		if (scriptInfo != null) {
			// successfully loaded
			scriptInfo.loadedCallback = onLoaded ?? cachedScriptInfo.loadedCallback;

			// do we need to clear the old script info?
			cachedScriptInfo.script = null;
			cachedScriptInfo.className = null;
			cachedScriptInfo.loadedCallback = null;
			scriptCache.remove(scriptName);

			// replace the old cached script info with the new one
			scriptCache.set(scriptName, scriptInfo);

			scriptInfo.loadedCallback(scriptName, scriptInfo);
		} else {
			// Log.error('Error loading script: ' + scriptDirectory + '/' + scriptName);
			cachedScriptInfo.loadedCallback(scriptName, null);
		}
	}

	public static function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);

		if (cachedScriptInfo != null) {
			// already loaded
			if (onLoaded != null) {
				onLoaded(scriptName, cachedScriptInfo);
			}
			return;
		}

		// TODO: do we want to include the script directory as the package, or add the script directory class path when building?
		// var fullScriptName = scriptDirectory + '.' + scriptName;
		// var fullScriptName = scriptName;

		// trace("Loading script: " + scriptName);
		// trace("Script directory: " + scriptDirectory);
		// trace("Script source directory: " + scriptSourceDirectory);

		// Watch the script source.  If it changes, recompile.
		if (hotCompileEnabled) {
			createHotCompileWatcher(scriptSourceDirectory, scriptName, (filename:String) -> {
				if (filename == null) {
					// we shouldn't get here, but just in case
					Log.error("Unknown script: " + scriptName);
					return;
				}

				// ensure the scriptSourceDirectory appears as a directory by appending a trailing slash
				scriptSourceDirectory = Path.addTrailingSlash(scriptSourceDirectory);

				var haxeArgs = ["-dce", "full", "-cp", "lib"];

				// if this successfully compiles, the hotreload watcher will pick up the change and reload the script
				var result = ScriptCompiler.compileScriptInternal("", scriptSourceDirectory, scriptDirectory, "cppia", haxeArgs, scriptName);

				if (result != 0) {
					// If the compilation failed, the script on disk will be the old version.
					// Should we call onLoaded(scriptName, null) if the compilation fails?
					// Log.error("Failed to compile script: " + scriptName);
					//cachedScriptInfo = scriptCache.get(scriptName);
					//if (cachedScriptInfo != null && cachedScriptInfo.loadedCallback != null) {
					//	cachedScriptInfo.loadedCallback(scriptName, null);
					//}
					onLoaded(scriptName, null);
					return;
				}
			});
		}

		// Watch for changes to the cppia file (the compiled script).
		// If it changes, reload the script.
		if (hotReloadEnabled) {
			createHotReloadWatcher(scriptDirectory, scriptName, (filename:String) -> {

				if (filename == null) {
					Log.error("Reload Watcher: Failed to reload script file (null filename): " + scriptName);
					return;
				}

				Log.info("Reload Watcher: Reloading script file: " + filename);

				var scriptInfo = createScriptInstance(scriptDirectory, scriptName);
				if (scriptInfo != null) {
					// successfully loaded
					scriptInfo.isExternal = true;

					onLoaded(scriptName, scriptInfo);
				} else {
					onLoaded(scriptName, null);
				}
			});
		}

		var scriptInfo = createScriptInstance(scriptDirectory, scriptName);

		if (scriptInfo != null) {
			// save the script into our cache
			scriptInfo.loadedCallback = onLoaded;
			scriptCache.set(scriptName, scriptInfo);

			onLoaded(scriptName, scriptInfo);
		} else {
			// Log.error('Error loading script: ' + scriptDirectory + '/' + scriptName);
			onLoaded(scriptName, null);
		}
		return;
	}

	public static function unload(scriptName:String):Void {
		if (scriptCache.exists(scriptName)) {
			scriptCache.remove(scriptName);
			Log.debug("Unloaded script: " + scriptName);
			// stop watching the script file
			#if (sys && scriptable)
			var cppiaFileWatcher = cppiaFileWatchers.get(scriptName);
			if (cppiaFileWatcher != null) {
				cppiaFileWatcher.dispose();
				cppiaFileWatchers.remove(scriptName);
			}

			var haxeSourceFileWatcher = haxeSourceFileWatchers.get(scriptName);
			if (haxeSourceFileWatcher != null) {
				haxeSourceFileWatcher.dispose();
				haxeSourceFileWatchers.remove(scriptName);
			}
			#end
		}
	}

	public static function dispose() {
		scriptCache.clear();
		#if (scriptable && sys)
		for (watcher in cppiaFileWatchers) {
			watcher.dispose();
		}
		cppiaFileWatchers.clear();

		for (watcher in haxeSourceFileWatchers) {
			watcher.dispose();
		}
		haxeSourceFileWatchers.clear();
		#end
	}
}
