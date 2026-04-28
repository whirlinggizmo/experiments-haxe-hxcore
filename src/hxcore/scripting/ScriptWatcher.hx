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

	public function watchSourceRoot(scriptSourceDirectory:String, onChanged:String->Void):FileWatcher {
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
			case HotCompileScope.SourceRoot:
				watchSourceRoot(scriptSourceDirectory, onChanged);
			case HotCompileScope.ScriptOnly:
				watchSource(scriptSourceDirectory, className, onChanged);
		};
		if (sourceWatcher != null) {
			haxeSourceFileWatchers.set(className, sourceWatcher);
		}
	}

	public function tick():Void {
		for (w in haxeSourceFileWatchers) {
			w.tick();
		}
		for (w in compiledFileWatchers) {
			w.tick();
		}
	}

	public function unload(scriptName:String):Void {
		removeCompiledWatcher(scriptName);
		removeSourceWatcher(scriptName);
		compiledLastReloadMtime.remove(scriptName);
	}

	public function dispose():Void {
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
	public function watchSourceRoot(scriptSourceDirectory:String, onChanged:String->Void):Dynamic {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
		return null;
	}
	public function watchHotCompile(scriptSourceDirectory:String, className:String, hotCompileScope:HotCompileScope, onChanged:String->Void):Void {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
	}
	public function watchHotReload(scriptDirectory:String, scriptName:String, onChanged:String->Void):Void {
		Log.warn("ScriptWatcher not available on this platform (requires sys)");
	}
	public function tick():Void {}
	public function unload(scriptName:String):Void {}
	public function dispose():Void {}
}
#end
