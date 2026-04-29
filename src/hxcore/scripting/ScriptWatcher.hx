package hxcore.scripting;

import hxcore.io.FileWatcher;
import hxcore.io.FileWatcher.FileChangeEvent;
import hxcore.util.Glob;
import hxcore.util.PathUtils;
import hxcore.util.DebouncedQueue;
import hxcore.logging.Log;
import haxe.Timer;
import hxcore.scripting.ScriptConfig.HotCompileScope;
import sys.FileSystem;

#if sys
class ScriptWatcher {
	public var debounceMs:Int;
	var coalescer:DebouncedQueue<String>;
	var pendingTimer:Timer;
	private var haxeSourceFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	private var compiledFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	private var compiledLastReloadMtime:Map<String, Float> = new Map<String, Float>();
	private var compiledDirectoryWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();

	public function new(?debounceMs:Int = 150) {
		this.debounceMs = debounceMs;
		this.coalescer = new DebouncedQueue<String>(this.debounceMs, (s) -> s);
		this.pendingTimer = null;
	}

	public function watchCompiled(scriptDirectory:String, scriptName:String, onChanged:String->Void):FileWatcher {
		scriptDirectory = PathUtils.ensureDirectory(PathUtils.normalizePath(scriptDirectory));
		var glob = "./" + ScriptPathResolver.classNameToPath(scriptName) + ".cppia";

		var watcher = new FileWatcher(scriptDirectory, (filename:String, event:FileChangeEvent) -> {
			if (event == FileChangeEvent.Removed) {
				Log.warn("Script file deleted " + filename);
				return;
			}
			if (event == FileChangeEvent.Added) {
				Log.debug("Script file added " + filename);
			} else {
				Log.debug("Script file changed: " + filename);
			}
			pushAndSchedule(filename, onChanged);
		});

		watcher.add(Glob.toEReg(glob));
		watcher.start();
		return watcher;
	}

	public function watchHotReload(scriptDirectory:String, scriptName:String, onChanged:String->Void):Void {
		removeCompiledWatcher(scriptName);
		var compiledWatcher = watchCompiled(scriptDirectory, scriptName, (filename:String) -> {
			if (filename == null) {
				Log.error("Reload Watcher: Failed to reload script file (null filename): " + scriptName);
				return;
			}
			if (!FileSystem.exists(filename)) {
				Log.warn("Reload Watcher: Script file missing, skipping reload: " + filename);
				return;
			}
			var mtime = FileSystem.stat(filename).mtime.getTime();
			if (compiledLastReloadMtime.exists(scriptName) && compiledLastReloadMtime.get(scriptName) == mtime) {
				Log.debug("Reload Watcher: Skipping duplicate reload for " + scriptName);
				return;
			}
			compiledLastReloadMtime.set(scriptName, mtime);
			onChanged(filename);
		});
		if (compiledWatcher != null) {
			compiledFileWatchers.set(scriptName, compiledWatcher);
		}
	}

	public function watchSource(scriptSourceDirectory:String, className:String, onChanged:String->Void):FileWatcher {
		scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
		var relativeSourcePath = ScriptPathResolver.relativeSourcePathWithinRoot(scriptSourceDirectory, className);
		if (relativeSourcePath == null) {
			Log.error('Script class name top level package does not match script source directory (${ScriptPathResolver.sourceRootPackage(scriptSourceDirectory)})');
			return null;
		}

		var watcher = new FileWatcher(scriptSourceDirectory, (filename:String, event:FileChangeEvent) -> {
			Log.debug("Script source file changed: " + filename);
			pushAndSchedule(filename, onChanged);
		});

		watcher.add(Glob.toEReg(relativeSourcePath));
		watcher.start();
		return watcher;
	}

	public function watchSourceDirectory(scriptSourceDirectory:String, onChanged:String->Void):FileWatcher {
		scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);
		var watcher = new FileWatcher(scriptSourceDirectory, (filename:String, event:FileChangeEvent) -> {
			Log.debug("Script source file changed: " + filename);
			pushAndSchedule(filename, onChanged);
		});

		watcher.add(Glob.toEReg("./**/*.hx"));
		watcher.start();
		return watcher;
	}

	public function watchHotCompile(scriptSourceDirectory:String, className:String, hotCompileScope:HotCompileScope, onChanged:String->Void):Void {
		removeSourceWatcher(className);
		var sourceWatcher = switch (hotCompileScope) {
			case HotCompileScope.ScriptDirectory:
				watchSourceDirectory(scriptSourceDirectory, onChanged);
			case HotCompileScope.ScriptFile:
				watchSource(scriptSourceDirectory, className, onChanged);
		};
		if (sourceWatcher != null) {
			haxeSourceFileWatchers.set(className, sourceWatcher);
		}
	}

	/**
	 * Watches the entire source script directory for any .hx file changes.
	 * Derives class names from file paths and fires onChanged with the className.
	 * This enables auto-compile of newly added scripts.
	 * onRemoved is called when a source file is deleted (to clean up compiled artifact).
	 */
	public function watchSourceDirectoryCompile(scriptSourceDirectory:String, onChanged:String->Void, ?onRemoved:String->Void):Void {
		var normalizedDir = PathUtils.normalizePath(scriptSourceDirectory);
		// Get parent directory to preserve package in class name derivation
		var parentDir = haxe.io.Path.directory(normalizedDir);

		Log.debug("Watching source script directory for compiles: " + normalizedDir);

		var watcher = new FileWatcher(normalizedDir, (filename:String, event:FileChangeEvent) -> {
			// Derive class name from the file path (using parent to preserve package)
			var className = ScriptPathResolver.classNameFromSourcePath(filename, parentDir);
			if (className == null) {
				Log.debug("Could not derive class name from: " + filename);
				return;
			}
			if (event == FileChangeEvent.Removed) {
				Log.debug("Source file removed: " + filename + " -> " + className);
				if (onRemoved != null) {
					onRemoved(className);
				}
				return;
			}
			if (event == FileChangeEvent.Added) {
				Log.debug("New source file detected: " + filename + " -> " + className);
			} else {
				Log.debug("Source file changed: " + filename + " -> " + className);
			}
			pushAndSchedule(className, onChanged);
		});

		watcher.add(Glob.toEReg("./**/*.hx"));
		watcher.start();
		// Store under a special key for directory-wide watching
		haxeSourceFileWatchers.set("__directory__", watcher);
	}

	public function stopWatchingSourceDirectoryCompile():Void {
		var watcher = haxeSourceFileWatchers.get("__directory__");
		if (watcher != null) {
			watcher.dispose();
			haxeSourceFileWatchers.remove("__directory__");
		}
	}

	/**
	 * Watches the entire compiled script directory for any .cppia file changes.
	 * Complement to watchSourceDirectory. Derives class names from file paths and only
	 * fires onChanged for already-loaded scripts. Includes mtime tracking to prevent
	 * duplicate reloads. onChanged receives the className for add/modify events.
	 * onRemoved receives className when a .cppia file is deleted.
	 */
	public function watchCompiledDirectory(scriptDirectory:String, isScriptLoaded:String->Bool, onChanged:String->Void, ?onRemoved:String->Void):Void {
		var normalizedDir = PathUtils.ensureDirectory(PathUtils.normalizePath(scriptDirectory));

		// Remove existing watcher for this directory if present
		if (compiledDirectoryWatchers.exists(normalizedDir)) {
			compiledDirectoryWatchers.get(normalizedDir).dispose();
		}

		Log.debug("Watching compiled script directory: " + normalizedDir);

		var watcher = new FileWatcher(normalizedDir, (filename:String, event:FileChangeEvent) -> {
			// Derive class name from the file path first (needed for both add/change and remove)
			var className = ScriptPathResolver.classNameFromCompiledPath(filename, "cppia", normalizedDir);
			if (className == null) {
				Log.debug("Could not derive class name from: " + filename);
				return;
			}

			if (event == FileChangeEvent.Removed) {
				Log.info("Compiled script removed: " + filename + " -> " + className);
				// Clear mtime tracking for this script
				compiledLastReloadMtime.remove(className);
				// Call onRemoved callback if script was loaded
				if (isScriptLoaded(className) && onRemoved != null) {
					onRemoved(className);
				}
				return;
			}

			// Only process if this script is already loaded
			if (!isScriptLoaded(className)) {
				Log.debug("Ignoring .cppia for unloaded script: " + className);
				return;
			}
			// Check mtime to prevent duplicate reloads
			var mtime = FileSystem.stat(filename).mtime.getTime();
			if (compiledLastReloadMtime.exists(className) && compiledLastReloadMtime.get(className) == mtime) {
				Log.debug("Skipping duplicate reload for " + className);
				return;
			}
			compiledLastReloadMtime.set(className, mtime);

			if (event == FileChangeEvent.Added) {
				Log.debug("New script file detected: " + filename + " -> " + className);
			} else {
				Log.debug("Script file changed: " + filename + " -> " + className);
			}
			pushAndSchedule(className, onChanged);
		});

		watcher.add(Glob.toEReg("./**/*.cppia"));
		watcher.start();
		compiledDirectoryWatchers.set(normalizedDir, watcher);
	}

	public function stopWatchingCompiledDirectory(scriptDirectory:String):Void {
		var normalizedDir = PathUtils.ensureDirectory(PathUtils.normalizePath(scriptDirectory));
		var watcher = compiledDirectoryWatchers.get(normalizedDir);
		if (watcher != null) {
			watcher.dispose();
			compiledDirectoryWatchers.remove(normalizedDir);
		}
	}

	public function tick():Void {
		for (w in haxeSourceFileWatchers) {
			w.tick();
		}
		for (w in compiledFileWatchers) {
			w.tick();
		}
		for (w in compiledDirectoryWatchers) {
			w.tick();
		}
	}

	public function unload(scriptName:String):Void {
		removeCompiledWatcher(scriptName);
		removeSourceWatcher(scriptName);
		compiledLastReloadMtime.remove(scriptName);
	}

	public function dispose():Void {
		for (watcher in compiledDirectoryWatchers) {
			watcher.dispose();
		}
		compiledDirectoryWatchers.clear();
		for (watcher in compiledFileWatchers) {
			watcher.dispose();
		}
		compiledFileWatchers.clear();

		for (watcher in haxeSourceFileWatchers) {
			watcher.dispose();
		}
		haxeSourceFileWatchers.clear();
		compiledLastReloadMtime.clear();
	}

	function pushAndSchedule(filename:String, onChanged:String->Void):Void {
		if (debounceMs <= 0) {
			onChanged(filename);
			return;
		}
		var nowMs = Std.int(Timer.stamp() * 1000);
		coalescer.push(filename, nowMs);
		scheduleFlush(onChanged);
	}

	function scheduleFlush(onChanged:String->Void):Void {
		if (pendingTimer != null) return;
		pendingTimer = Timer.delay(() -> {
			pendingTimer = null;
			var nowMs = Std.int(Timer.stamp() * 1000);
			var changed = coalescer.flush(nowMs);
			if (changed.length == 0) {
				scheduleFlush(onChanged);
				return;
			}
			for (path in changed) {
				onChanged(path);
			}
		}, debounceMs);
	}

	private function removeCompiledWatcher(scriptName:String):Void {
		var compiledWatcher = compiledFileWatchers.get(scriptName);
		if (compiledWatcher != null) {
			compiledWatcher.dispose();
			compiledFileWatchers.remove(scriptName);
		}
	}

	private function removeSourceWatcher(scriptName:String):Void {
		var sourceWatcher = haxeSourceFileWatchers.get(scriptName);
		if (sourceWatcher != null) {
			sourceWatcher.dispose();
			haxeSourceFileWatchers.remove(scriptName);
		}
	}
}
#else
class ScriptWatcher {
	public var debounceMs:Int;
	public function new(?debounceMs:Int = 150) {
		this.debounceMs = debounceMs;
	}
	public function watchCompiled(scriptDirectory:String, scriptName:String, onChanged:String->Void):Dynamic {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
		return null;
	}
	public function watchSource(scriptSourceDirectory:String, className:String, onChanged:String->Void):Dynamic {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
		return null;
	}
	public function watchSourceDirectory(scriptSourceDirectory:String, onChanged:String->Void):Dynamic {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
		return null;
	}
	public function watchHotCompile(scriptSourceDirectory:String, className:String, hotCompileScope:HotCompileScope, onChanged:String->Void):Void {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
	}
	public function watchSourceDirectoryCompile(scriptSourceDirectory:String, onChanged:String->Void, ?onRemoved:String->Void):Void {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
	}
	public function stopWatchingSourceDirectoryCompile():Void {}
	public function watchHotReload(scriptDirectory:String, scriptName:String, onChanged:String->Void):Void {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
	}
	public function watchCompiledDirectory(scriptDirectory:String, isScriptLoaded:String->Bool, onChanged:String->Void, ?onRemoved:String->Void):Void {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
	}
	public function stopWatchingCompiledDirectory(scriptDirectory:String):Void {}
	public function tick():Void {}
	public function unload(scriptName:String):Void {}
	public function dispose():Void {}
}
#end
