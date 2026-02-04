// src/hxcore/scripting/ScriptLoader.cpp.hx
package hxcore.scripting;

import hxcore.util.Glob;
import sys.io.File;
import hxcore.logging.Log;
import hxcore.util.TypeUtils;
import hxcore.scripting.Script;
import haxe.io.Path;
import hxcore.util.PathUtils;
import hxcore.scripting.ScriptResolution;
import hxcore.scripting.ScriptResolution.OverrideMode;
import hxcore.scripting.ScriptResolution.ScriptSource;
import hxcore.scripting.Types.HotCompileScope;
import hxcore.scripting.Types.ScriptInfo;
#if sys
import hxcore.scripting.ScriptCompiler;
import hxcore.scripting.ScriptWatcher;
import hxcore.io.FileWatcher;
import hxcore.io.FileWatcher.FileChangeEvent;
import sys.FileSystem;
#if scriptable
import cpp.cppia.Module;
#end
#end
class ScriptLoader implements IScriptLoader {
	public function new() {}
	private var scriptCache:Map<String, ScriptInfo> = new Map<String, ScriptInfo>();
	private var scriptDirectory:String;
	private var scriptSourceDirectory:String;
	private var classesInfoPath:String = ".";
	private var hotReloadEnabled:Bool = false;
	private var hotCompileEnabled:Bool = false;
	private var externalScriptsEnabled:Bool = false;
	private var overrideMode:OverrideMode = OverrideMode.ExternalFirst;
	private var changeDebounceMs:Int = 150;
	private var hotCompileScope:HotCompileScope = HotCompileScope.ScriptOnly;
	private var watcher:ScriptWatcher = null;

	#if sys
	private var haxeSourceFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	private var cppiaFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	private var cppiaLastReloadMtime:Map<String, Float> = new Map<String, Float>();
	#end

	// ============================================================================
	// UTILITY FUNCTIONS
	// ============================================================================


	/*
// replaced with Glob.toERegString
	private function buildFileFilter(className:String, extension:String):String {
		var filter = className;

		// Convert package dots to path separators
		filter = StringTools.replace(filter, ".", "/");

		// Escape special regex characters
		filter = StringTools.replace(filter, "/", "\\/");
		filter = StringTools.replace(filter, "*", ".*");
		filter = StringTools.replace(filter, "?", "\\?");

		// Add extension
		filter = filter + "\\." + extension;

		// Make it an exact match
		return "^" + filter + "$";
	}
	*/


	public function setScriptDirectory(scriptDirectory:String):Void {
		this.scriptDirectory = PathUtils.normalizePath(scriptDirectory);
	}

	public function setScriptSourceDirectory(scriptSourceDirectory:String):Void {
		this.scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
	}

	public function enableExternalScripts(scriptDirectory:String):Void {
		#if (!sys || !scriptable)
		Log.warn("External script loading not available on this platform (requires sys, scriptable)");
		return;
		#end
		this.scriptDirectory = PathUtils.normalizePath(scriptDirectory);
		externalScriptsEnabled = true;

		#if !emscripten
		enableJITCompilation(true);
		#end
	}

	public function setExternalEnabled(enable:Bool, ?scriptDirectory:String):Void {
		if (enable) {
			if (scriptDirectory != null) {
				enableExternalScripts(scriptDirectory);
			} else if (this.scriptDirectory != null) {
				enableExternalScripts(this.scriptDirectory);
			} else {
				Log.warn("External scripts enabled without script directory");
				externalScriptsEnabled = true;
			}
		} else {
			externalScriptsEnabled = false;
		}
	}

	public function setOverrideMode(mode:OverrideMode):Void {
		overrideMode = mode;
	}

	public function setChangeDebounceMs(ms:Int):Void {
		if (ms < 0) {
			Log.warn("Debounce must be >= 0");
			return;
		}
		changeDebounceMs = ms;
		if (watcher != null) {
			watcher.debounceMs = changeDebounceMs;
		}
	}

	/**
	 * Force a watcher scan pass (useful for deterministic tests).
	 */
	public function tickWatchers():Void {
		#if sys
		for (w in haxeSourceFileWatchers) {
			w.tick();
		}
		for (w in cppiaFileWatchers) {
			w.tick();
		}
		#end
	}

	public function enableJITCompilation(enable:Bool):Void {
		#if (!cpp || !scriptable || emscripten)
		Log.warn("JIT compilation not available on this platform (requires cpp + scriptable, not emscripten)");
		return;
		#else
		cpp.cppia.Host.enableJit(enable);
		#end
	}


	public function enableHotReload():Void {
		#if (sys && scriptable)
		hotReloadEnabled = true;
		#else
		Log.warn("Hot reload not available on this platform (requires sys, scriptable)");
		#end
	}

	public function setHotReloadEnabled(enable:Bool):Void {
		if (enable) {
			enableHotReload();
		} else {
			hotReloadEnabled = false;
		}
	}

	public function enableHotCompile(scriptSourceDirectory:String):Void {
		#if sys
		this.scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
		hotCompileEnabled = true;
		#else
		Log.warn("Hot compile not available on this platform (requires sys)");
		#end
	}

	public function setHotCompileEnabled(enable:Bool, ?scriptSourceDirectory:String):Void {
		if (enable) {
			if (scriptSourceDirectory == null) {
				Log.warn("Hot compile enabled without script source directory");
				return;
			}
			enableHotCompile(scriptSourceDirectory);
		} else {
			hotCompileEnabled = false;
		}
	}

	public function setHotCompileScope(scope:HotCompileScope):Void {
		hotCompileScope = scope;
	}

	private function getClassName(scriptDirectory:String, scriptName:String):String {
		// the scriptName is the class name of the script, so replace any '.' with '/'
		var parts:Array<String> = scriptName.split('.');
		var className:String = parts[parts.length - 1];
		// Log.debug("className: " + className);
		return className;
	}

	/*
	private function getClassPath(scriptDirectory:String, scriptName:String):String {
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
	*/


	private function validateWatcherSetup(scriptDirectory:String, scriptName:String, requiresExternal:Bool = false):Bool {
		if (requiresExternal && !externalScriptsEnabled) {
			Log.warn("External scripts not enabled");
			return false;
		}
		if (scriptName == null || scriptName.length == 0) {
			Log.warn("No script name specified");
			return false;
		}
		if (scriptDirectory == null || scriptDirectory.length == 0) {
			Log.warn("No script directory specified");
			return false;
		}
		return true;
	}

	/**
	 * createHotReloadWatcher()
	 * Sets up a file watcher for the script file (.cppia) and calls the onChanged callback when the file changes
	 * @param scriptDirectory : The root directory of the scripts (.cppia)
	 * @param scriptName : The script (class) to watch.  e.g., "Test" or "mypackage.Test"
	 * @param onChanged : The callback to call when the file changes. String->Void
	 */
	private function createHotReloadWatcher(scriptDirectory:String, scriptName:String, onChanged:String->Void) {
		if (!hotReloadEnabled) {
			Log.warn("Hot reload not enabled");
			return;
		}
		#if (sys && scriptable)
		if (!validateWatcherSetup(scriptDirectory, scriptName, true)) {
			return;
		}

		scriptDirectory = PathUtils.normalizePath(scriptDirectory);

		Log.debug("Path for compiled script files(.cppia) files is: " + scriptDirectory);

		// remove any existing cppia file watchers
		if (cppiaFileWatchers.exists(scriptName)) {
			cppiaFileWatchers[scriptName].stop();
			cppiaFileWatchers.remove(scriptName);
		}

		var classNameAsPath = StringTools.replace(scriptName, ".", "/");

		// script directory should be a directory, but without the 'scripts' part.  
		// so we don't need to remove it from the classNameAsPath
		scriptDirectory = PathUtils.ensureDirectory(scriptDirectory);

		if (watcher == null) {
			watcher = new ScriptWatcher(changeDebounceMs);
		}
		var cppiaFileWatcher = watcher.watchCompiled(scriptDirectory, scriptName, onChanged);
		if (cppiaFileWatcher != null) {
			cppiaFileWatchers.set(scriptName, cppiaFileWatcher);
		}
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
	private function createHotCompileWatcher(scriptSourceDirectory:String, className:String, scriptChangedCallback:String->Void) {
		if (!hotCompileEnabled) {
			Log.warn("Hot compile not enabled");
			return;
		}

		#if (sys && scriptable)
		if (!validateWatcherSetup(scriptSourceDirectory, className)) {
			return;
		}

		scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
		Log.debug("Path for script source files(.hx) files is: " + scriptSourceDirectory);

		// look for the export_classes.filtered.info file in the scriptSourceDirectory (which includes the scripts package directory)
		classesInfoPath = Path.join([scriptSourceDirectory, "export_classes.filtered.info"]);

		// the scriptSourceDirectory includes the top level script package directory already.
		// we need to remove one of them (from the scripts directory, or from the className)
		// we'll remove it from the className so we can restrict the watcher to files/directories under the scripts directory
		// instead of all directories and files that are siblings (like src, bin, etc.).
		
		var scriptSourceDirectoryTail = PathUtils.getDirectoryTail(scriptSourceDirectory);
		var classNameParts = className.split(".");
		var classNameTopLevelPackage = classNameParts.shift();
		// sanity check, make sure the first part of the script name (top level package) is the same we just removed
		if (classNameTopLevelPackage != scriptSourceDirectoryTail) {
			Log.error('Script class name top level package ($classNameTopLevelPackage) does not match script source directory ($scriptSourceDirectoryTail)');
			return;
		}

		if (haxeSourceFileWatchers.exists(className)) {
			haxeSourceFileWatchers[className].stop();
			haxeSourceFileWatchers.remove(className);
		}

		// break the scriptName into the package name and class name
		//var className = getClassName(scriptDirectory, scriptName);
		//var scriptSourceFileFilter = buildFileFilter(className, "hx");

		if (watcher == null) {
			watcher = new ScriptWatcher(changeDebounceMs);
		}
		// TODO: Consider dependency tracking to avoid recompiling on unrelated changes.
		var haxeSourceFileWatcher = switch (hotCompileScope) {
			case HotCompileScope.SourceRoot:
				watcher.watchSourceRoot(scriptSourceDirectory, scriptChangedCallback);
			case HotCompileScope.ScriptOnly:
				watcher.watchSource(scriptSourceDirectory, className, scriptChangedCallback);
		};
		if (haxeSourceFileWatcher != null) {
			haxeSourceFileWatchers.set(className, haxeSourceFileWatcher);
		}
		#else
		Log.warn("HotCompileWatcher not created (requires sys, -D scriptable)");
		#end
	}

	/**
	 * Try to load a script class from the script directory or fallback to compiled-in scripts.
	 * Ensures class is derived from Script, instantiates it, and sets metadata.
	 */
	private function createScriptInstance(scriptDirectory:String, className:String):ScriptInfo {
		scriptDirectory = Path.addTrailingSlash(PathUtils.normalizePath(scriptDirectory));
		var classNameAsPath = StringTools.replace(className, ".", "/");
		var sourceFilePath = PathUtils.normalizePath(Path.join([scriptDirectory, classNameAsPath + ".cppia"]));
		var resolvedClass:Class<Dynamic> = null;
		final scriptInfo:ScriptInfo = {className: className, sourcePath: sourceFilePath};
		#if scriptable
		var internalClass:Class<Dynamic> = Type.resolveClass(className);
		var hasInternal = internalClass != null;
		var hasExternal = externalScriptsEnabled && FileSystem.exists(scriptDirectory) && FileSystem.exists(sourceFilePath);
		var sourceChoice = ScriptResolution.chooseSourceWithExternalEnabled(hasExternal, hasInternal, externalScriptsEnabled, overrideMode);

		function tryLoadExternal():Class<Dynamic> {
			try {
				final fileBytes = File.getBytes(sourceFilePath);
				if (fileBytes == null) throw 'Failed to load module (bad data): $sourceFilePath';
				final data = fileBytes.getData();
				if (data == null) throw 'Failed to load module (bad data): $sourceFilePath';

				final module = Module.fromData(data);
				module.boot();
				// module.run();

				// prepend the generated script namespace to the class name if it's not empty
				var generatedScriptNamespace = ScriptCompiler.getGeneratedScriptNamespace();
				var generatedClassName = (generatedScriptNamespace.length > 0) ? generatedScriptNamespace + "." + className : className;

				var cls = module.resolveClass(generatedClassName);
				if (cls == null) throw 'Failed to resolve cppia class: $generatedClassName';
				scriptInfo.isExternal = true;
				scriptInfo.sourcePath = sourceFilePath;
				return cls;
			} catch (e:Dynamic) {
				#if cpp
				Sys.println(haxe.CallStack.exceptionStack());
				#end
				Log.warn('Failed to load cppia module: $sourceFilePath\n' + Std.string(e));
				return null;
			}
		}

		switch (sourceChoice) {
			case ScriptSource.External:
				resolvedClass = tryLoadExternal();
				if (resolvedClass == null && overrideMode == OverrideMode.ExternalFirst && hasInternal) {
					resolvedClass = internalClass;
					scriptInfo.isExternal = false;
					scriptInfo.sourcePath = className;
				}
			case ScriptSource.Internal:
				resolvedClass = internalClass;
				if (resolvedClass != null) {
					scriptInfo.isExternal = false;
					scriptInfo.sourcePath = className;
				}
			case ScriptSource.None:
		}
		#end

		if (resolvedClass == null) {
			// we didn't find the class in the generated script directory (or it's disabled), try the baked in scripts
			try {
				Log.debug('Trying to resolve class from built-in scripts: $className');
				resolvedClass = Type.resolveClass(className);
				if (resolvedClass == null) {
					throw 'Failed to resolve class from built-in scripts: $className';
				}
				scriptInfo.isExternal = false;
				scriptInfo.sourcePath = className;
			} catch (e:Dynamic) {
				Log.error('Failed to resolve built-in class: $className\n${e.message}');
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

	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
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

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);

		if (cachedScriptInfo != null) {
			// already loaded
			if (onLoaded != null) {
				onLoaded(scriptName, cachedScriptInfo);
			}
			return;
		}

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
				scriptSourceDirectory = Path.addTrailingSlash(PathUtils.normalizePath(scriptSourceDirectory));

				var haxeArgs = ["-lib", "hxcore"];

				var scriptSourceAbsolutePath = PathUtils.toAbsolutePath(scriptSourceDirectory);
				var classesInfoAbsolutePath = PathUtils.toAbsolutePath(classesInfoPath);
				var outputAbsolutePath = PathUtils.toAbsolutePath(scriptDirectory);
				var rootDir = PathUtils.getSourceRootParent(scriptSourceAbsolutePath);
				// Ensure the root directory (parent of scripts) is on the classpath for package resolution.
				if (rootDir != null && rootDir.length > 0) {
					haxeArgs.push("-cp");
					haxeArgs.push(rootDir);
				}

				// if this successfully compiles, the hotreload watcher will pick up the change and reload the script
				// Use the new macro-based approach instead of temporary files
				var result = ScriptCompiler.compileScriptInternal(rootDir, scriptSourceAbsolutePath, outputAbsolutePath, classesInfoAbsolutePath, "cppia",
					haxeArgs, scriptName);

				if (result != 0) {
					// If the compilation failed, the script on disk will be the old version.
					Log.warn("Hot compile failed, keeping previous script: " + scriptName);
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
				if (!FileSystem.exists(filename)) {
					Log.warn("Reload Watcher: Script file missing, skipping reload: " + filename);
					return;
				}
				var mtime = FileSystem.stat(filename).mtime.getTime();
				if (cppiaLastReloadMtime.exists(scriptName) && cppiaLastReloadMtime.get(scriptName) == mtime) {
					Log.debug("Reload Watcher: Skipping duplicate reload for " + scriptName);
					return;
				}
				cppiaLastReloadMtime.set(scriptName, mtime);

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

	public function unload(scriptName:String):Void {
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

	public function dispose() {
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
