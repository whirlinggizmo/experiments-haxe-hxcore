// src/hxcore/scripting/ScriptLoader.cpp.hx
package hxcore.scripting;

import sys.io.File;
import hxcore.logging.Log;
import hxcore.util.TypeUtils;
import hxcore.scripting.Script;
import haxe.io.Path;
import hxcore.util.PathUtils;
import hxcore.scripting.ScriptResolution;
import hxcore.scripting.ScriptResolution.OverrideMode;
import hxcore.scripting.ScriptResolution.ScriptSource;
import hxcore.scripting.ScriptConfig.HotCompileScope;
import hxcore.scripting.IScriptLoader.ScriptInfo;
#if sys
import hxcore.scripting.ScriptCompiler;
import hxcore.scripting.ScriptWatcher;
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
	private var externalScriptsEnabled:Bool = false;
	private var overrideMode:OverrideMode = OverrideMode.ExternalFirst;
	private var changeDebounceMs:Int = 150;
	private var hotReloadEnabled:Bool = false;
	private var hotCompileEnabled:Bool = false;
	private var hotCompileScope:HotCompileScope = HotCompileScope.ScriptDirectory;
	private var classesInfoPath:String = ".";
	private var watcher:ScriptWatcher = null;
	private var directoryHotReloadEnabled:Bool = false;
	private var directoryHotCompileEnabled:Bool = false;

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
		if (watcher != null) {
			watcher.tick();
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

	private function createEmptyScriptInfo(className:String, sourceFilePath:String):ScriptInfo {
		return {className: className, sourcePath: sourceFilePath};
	}

	private function populateInternalSource(scriptInfo:ScriptInfo, className:String):Void {
		scriptInfo.isExternal = false;
		scriptInfo.sourcePath = className;
	}

	#if scriptable
	private function loadExternalClass(sourceFilePath:String, className:String, scriptInfo:ScriptInfo):Class<Dynamic> {
		try {
			final fileBytes = File.getBytes(sourceFilePath);
			if (fileBytes == null) throw 'Failed to load module (bad data): $sourceFilePath';
			final data = fileBytes.getData();
			if (data == null) throw 'Failed to load module (bad data): $sourceFilePath';

			final module = Module.fromData(data);
			module.boot();

			var generatedScriptNamespace = ScriptCompiler.getGeneratedScriptNamespace();
			var generatedClassName = ScriptPathResolver.generatedClassName(className, generatedScriptNamespace);

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

	private function resolveScriptClass(sourceFilePath:String, className:String, scriptInfo:ScriptInfo):Class<Dynamic> {
		var internalClass:Class<Dynamic> = Type.resolveClass(className);
		var hasInternal = internalClass != null;
		var hasExternal = externalScriptsEnabled && FileSystem.exists(scriptDirectory) && FileSystem.exists(sourceFilePath);
		var sourceChoice = ScriptResolution.chooseSourceWithExternalEnabled(hasExternal, hasInternal, externalScriptsEnabled, overrideMode);

		return switch (sourceChoice) {
			case ScriptSource.External:
				var externalClass = loadExternalClass(sourceFilePath, className, scriptInfo);
				if (externalClass == null && overrideMode == OverrideMode.ExternalFirst && hasInternal) {
					populateInternalSource(scriptInfo, className);
					internalClass;
				} else {
					externalClass;
				}
			case ScriptSource.Internal:
				if (internalClass != null) {
					populateInternalSource(scriptInfo, className);
				}
				internalClass;
			case ScriptSource.None:
				null;
		}
	}
	#end

	private function resolveInternalFallback(className:String, scriptInfo:ScriptInfo):Class<Dynamic> {
		try {
			Log.debug('Trying to resolve class from built-in scripts: $className');
			var resolvedClass = Type.resolveClass(className);
			if (resolvedClass == null) {
				throw 'Failed to resolve class from built-in scripts: $className';
			}
			populateInternalSource(scriptInfo, className);
			return resolvedClass;
		} catch (e:Dynamic) {
			Log.error('Failed to resolve built-in class: $className\n${e.message}');
			return null;
		}
	}

	private function instantiateScript(resolvedClass:Class<Dynamic>, className:String, scriptInfo:ScriptInfo):ScriptInfo {
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
		scriptInfo.script.scriptName = className;
		scriptInfo.script.scriptDirectory = scriptInfo.sourcePath;
		return scriptInfo;
	}

	private function createScriptInstance(scriptDirectory:String, className:String):ScriptInfo {
		scriptDirectory = Path.addTrailingSlash(PathUtils.normalizePath(scriptDirectory));
		var sourceFilePath = ScriptPathResolver.compiledScriptPath(scriptDirectory, className);
		var scriptInfo = createEmptyScriptInfo(className, sourceFilePath);
		var resolvedClass:Class<Dynamic> = null;

		#if scriptable
		resolvedClass = resolveScriptClass(sourceFilePath, className, scriptInfo);
		#end

		if (resolvedClass == null) {
			resolvedClass = resolveInternalFallback(className, scriptInfo);
		}

		return resolvedClass == null ? null : instantiateScript(resolvedClass, className, scriptInfo);
	}

	private function replaceCachedScript(scriptName:String, scriptInfo:ScriptInfo, ?onLoaded:String->ScriptInfo->Void):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);
		var loadedCallback = onLoaded;
		if (loadedCallback == null && cachedScriptInfo != null) {
			loadedCallback = cachedScriptInfo.loadedCallback;
		}

		if (cachedScriptInfo != null) {
			cachedScriptInfo.script = null;
			cachedScriptInfo.className = null;
			cachedScriptInfo.loadedCallback = null;
		}

		scriptInfo.loadedCallback = loadedCallback;
		scriptCache.set(scriptName, scriptInfo);
		if (loadedCallback != null) {
			loadedCallback(scriptName, scriptInfo);
		}
	}

	private function failCachedReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);
		if (cachedScriptInfo == null) {
			return;
		}
		var loadedCallback = onLoaded != null ? onLoaded : cachedScriptInfo.loadedCallback;
		if (loadedCallback != null) {
			loadedCallback(scriptName, null);
		}
		// Note: We don't unload here - let the caller decide if unload is appropriate
		// to avoid use-after-free issues during active reload operations
	}

	private function loadAndCacheScript(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		var scriptInfo = createScriptInstance(scriptDirectory, scriptName);
		if (scriptInfo == null) {
			onLoaded(scriptName, null);
			return;
		}
		replaceCachedScript(scriptName, scriptInfo, onLoaded);
	}

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

	private function validateHotCompileScriptRoot(scriptName:String):Bool {
		scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
		Log.debug("Path for script source files(.hx) files is: " + scriptSourceDirectory);
		classesInfoPath = ScriptPathResolver.exportClassesInfoPath(scriptSourceDirectory);
		var scriptSourceDirectoryTail = ScriptPathResolver.sourceRootPackage(scriptSourceDirectory);
		var classNameParts = scriptName.split(".");
		var classNameTopLevelPackage = classNameParts.shift();
		if (classNameTopLevelPackage != scriptSourceDirectoryTail) {
			Log.error('Script class name top level package ($classNameTopLevelPackage) does not match script source directory ($scriptSourceDirectoryTail)');
			return false;
		}
		return true;
	}

	private function ensureWatchCoordinator():Void {
		#if sys
		if (watcher == null) {
			watcher = new ScriptWatcher(changeDebounceMs);
		}
		#end
	}

	private function setupDirectoryHotCompileWatch():Bool {
		if (!hotCompileEnabled || directoryHotCompileEnabled) {
			return true;
		}
		if (scriptSourceDirectory == null || scriptSourceDirectory.length == 0) {
			Log.warn("Hot compile requires script source directory");
			return false;
		}
		// Ensure source directory and classes info path are set
		scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
		classesInfoPath = ScriptPathResolver.exportClassesInfoPath(scriptSourceDirectory);
		ensureWatchCoordinator();

		// Watch entire source directory, derive class names from paths, compile any changed/added script
		watcher.watchSourceDirectoryCompile(scriptSourceDirectory, (className:String) -> {
			Log.info("Directory Compile Watcher: Source changed for: " + className);
			// Compile the changed file, plus recompile all loaded external scripts
			// (to handle dependency changes - if Dep.hx changes, Test.hx that uses it needs recompile)
			var scriptsToCompile = [className];
			for (loadedName => _ in scriptCache) {
				if (loadedName != className && !scriptsToCompile.contains(loadedName)) {
					scriptsToCompile.push(loadedName);
				}
			}
			for (scriptToCompile in scriptsToCompile) {
				Log.debug("Recompiling due to source change: " + scriptToCompile);
				var result = ScriptCompiler.compileCppia(scriptSourceDirectory, scriptDirectory, classesInfoPath, scriptToCompile);
				if (result != 0) {
					Log.warn("Hot compile failed for: " + scriptToCompile);
				}
			}
		}, (className:String) -> {
			// Source file removed - delete the compiled .cppia to clean up
			Log.info("Source removed, deleting compiled: " + className);
			var cppiaPath = ScriptPathResolver.compiledScriptPath(scriptDirectory, className, "cppia");
			if (FileSystem.exists(cppiaPath)) {
				try {
					FileSystem.deleteFile(cppiaPath);
					Log.debug("Deleted compiled script: " + cppiaPath);
				} catch (e:Dynamic) {
					Log.warn("Failed to delete compiled script: " + cppiaPath + " - " + e);
				}
			}
			// Also unload if currently loaded
			unload(className);
		});

		directoryHotCompileEnabled = true;
		return true;
	}

	/** @deprecated Use setupDirectoryHotCompileWatch instead */
	private function setupHotCompileWatch(scriptName:String):Bool {
		// When using ScriptDirectory scope, delegate to directory-wide watch
		if (hotCompileScope == HotCompileScope.ScriptDirectory) {
			return setupDirectoryHotCompileWatch();
		}
		// Fallback to per-file watching for ScriptFile scope
		if (!hotCompileEnabled) {
			return true;
		}
		if (!validateWatcherSetup(scriptSourceDirectory, scriptName)) {
			return false;
		}
		if (!validateHotCompileScriptRoot(scriptName)) {
			return false;
		}
		ensureWatchCoordinator();
		watcher.watchHotCompile(scriptSourceDirectory, scriptName, hotCompileScope, (filename:String) -> {
			if (filename == null) {
				Log.error("Unknown script: " + scriptName);
				return;
			}
			var result = ScriptCompiler.compileCppia(scriptSourceDirectory, scriptDirectory, classesInfoPath, scriptName);
			if (result != 0) {
				Log.warn("Hot compile failed, keeping previous script: " + scriptName);
			}
		});
		return true;
	}

	private function setupDirectoryHotReloadWatch():Bool {
		if (!hotReloadEnabled || directoryHotReloadEnabled) {
			return true;
		}
		if (scriptDirectory == null || scriptDirectory.length == 0) {
			Log.warn("Hot reload requires script directory");
			return false;
		}
		scriptDirectory = PathUtils.normalizePath(scriptDirectory);
		Log.debug("Setting up directory hot reload watch for: " + scriptDirectory);

		// Ensure directory exists so FileWatcher can scan it
		if (!FileSystem.exists(scriptDirectory)) {
			Log.debug("Creating script directory: " + scriptDirectory);
			FileSystem.createDirectory(scriptDirectory);
		}
		scriptDirectory = PathUtils.ensureDirectory(scriptDirectory);
		ensureWatchCoordinator();

		// Watch entire directory, derive class names from paths
		// onChanged: reload when .cppia is added/modified
		// onRemoved: unload when .cppia is deleted
		watcher.watchCompiledDirectory(scriptDirectory, (className:String) -> scriptCache.exists(className), (className:String) -> {
			Log.info("Directory Reload Watcher: Reloading script: " + className);
			forceReload(className);
		}, (className:String) -> {
			Log.info("Directory Reload Watcher: Unloading script (file removed): " + className);
			unload(className);
		});

		directoryHotReloadEnabled = true;
		return true;
	}

	/** @deprecated Use setupDirectoryHotReloadWatch instead */
	private function setupHotReloadWatch(scriptName:String):Bool {
		// Delegate to directory watch (it's now all handled centrally)
		return setupDirectoryHotReloadWatch();
	}

	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		if (!scriptCache.exists(scriptName)) {
			Log.warn("Unable to reload script that hasn't already been loaded: " + scriptName);
			return;
		}

		var scriptInfo = createScriptInstance(scriptDirectory, scriptName);
		if (scriptInfo != null) {
			replaceCachedScript(scriptName, scriptInfo, onLoaded);
		} else {
			failCachedReload(scriptName, onLoaded);
		}
	}

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);

		if (cachedScriptInfo != null) {
			if (cachedScriptInfo.script != null) {
				// already loaded and active
				if (onLoaded != null) {
					onLoaded(scriptName, cachedScriptInfo);
				}
				return;
			}
			// soft-unloaded (subscription exists but no active script) - try to reload
			// update the callback in case caller passed a new one
			if (onLoaded != null) {
				cachedScriptInfo.loadedCallback = onLoaded;
			}
			forceReload(scriptName, cachedScriptInfo.loadedCallback);
			return;
		}
		if (!setupHotCompileWatch(scriptName)) {
			return;
		}
		if (!setupHotReloadWatch(scriptName)) {
			return;
		}
		loadAndCacheScript(scriptName, onLoaded);
	}

	public function unload(scriptName:String):Void {
		var cachedScriptInfo = scriptCache.get(scriptName);
		if (cachedScriptInfo != null && cachedScriptInfo.script != null) {
			// Soft-unload: null the script instance but keep the cache entry as a
			// subscription so the watcher can reload when the file reappears.
			cachedScriptInfo.script = null;
			Log.debug("Soft-unloaded script (subscription retained): " + scriptName);
			// Notify the listener (e.g. ScriptHost) so it stops using the old instance.
			if (cachedScriptInfo.loadedCallback != null) {
				cachedScriptInfo.loadedCallback(scriptName, null);
			}
			// Attempt immediate fallback to internal class if available.
			forceReload(scriptName);
		}
	}

	/**
	 * Returns true if the script has an active (non-null) script instance.
	 * A soft-unloaded script has a cache entry but returns false here.
	 */
	public function isLoaded(scriptName:String):Bool {
		var info = scriptCache.get(scriptName);
		return info != null && info.script != null;
	}

	/**
	 * Returns true if the script has a subscription (was ever loaded via load()),
	 * even if it is currently soft-unloaded.
	 */
	public function isSubscribed(scriptName:String):Bool {
		return scriptCache.exists(scriptName);
	}

	public function dispose() {
		scriptCache.clear();
		#if sys
		if (watcher != null) {
			watcher.dispose();
			watcher = null;
		}
		#end
	}
}
