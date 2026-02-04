package hxcore.scripting;

import hxcore.io.FileWatcher;
import hxcore.io.FileWatcher.FileChangeEvent;
import hxcore.util.Glob;
import hxcore.util.PathUtils;
import hxcore.logging.Log;
import haxe.Timer;
import hxcore.scripting.Types.HotCompileScope;

#if sys
class ScriptWatcher {
	public var debounceMs:Int;
	var coalescer:ScriptChangeCoalescer;
	var pendingTimer:Timer;

	public function new(?debounceMs:Int = 150) {
		this.debounceMs = debounceMs;
		this.coalescer = new ScriptChangeCoalescer(this.debounceMs);
		this.pendingTimer = null;
	}

	public function watchCompiled(scriptDirectory:String, scriptName:String, onChanged:String->Void):FileWatcher {
		scriptDirectory = PathUtils.ensureDirectory(PathUtils.normalizePath(scriptDirectory));
		var classNameAsPath = StringTools.replace(scriptName, ".", "/");
		var glob = "./" + classNameAsPath + ".cppia";

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

	public function watchSource(scriptSourceDirectory:String, className:String, onChanged:String->Void):FileWatcher {
		scriptSourceDirectory = PathUtils.normalizePath(scriptSourceDirectory);

		var scriptSourceDirectoryTail = PathUtils.getDirectoryTail(scriptSourceDirectory);
		var classNameParts = className.split(".");
		var classNameTopLevelPackage = classNameParts.shift();
		if (classNameTopLevelPackage != scriptSourceDirectoryTail) {
			Log.error('Script class name top level package ($classNameTopLevelPackage) does not match script source directory ($scriptSourceDirectoryTail)');
			return null;
		}

		var classNameAsPathWithoutTopLevelPackage = classNameParts.join("/");
		classNameAsPathWithoutTopLevelPackage = "./" + classNameAsPathWithoutTopLevelPackage + ".hx";

		var watcher = new FileWatcher(scriptSourceDirectory, (filename:String, event:FileChangeEvent) -> {
			Log.debug("Script source file changed: " + filename);
			pushAndSchedule(filename, onChanged);
		});

		watcher.add(Glob.toEReg(classNameAsPathWithoutTopLevelPackage));
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
}
#end
