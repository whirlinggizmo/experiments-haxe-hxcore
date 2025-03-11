package core.scripting;

import core.logging.Log;
import core.util.TypeUtils;
import core.scripting.Script;
import core.scripting.ScriptContext;
import core.scripting.ScriptCompiler;
import haxe.io.Path;
#if scriptable
import core.io.FileWatcher;
import core.io.FileWatcher.FileEvent;
import sys.FileSystem;
import sys.io.File;
import cpp.cppia.Host;
import cpp.cppia.Module;
#end

class ScriptLoader {
	private static var scriptCache:Map<String, Script> = new Map<String, Script>();
	public static var scriptDirectory:String = "./scripts/";
	public static var scriptSourceDirectory:String = "./src/";
	#if scriptable
	private static var cppiaFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	private static var haxeSourceFileWatchers:Map<String, FileWatcher> = new Map<String, FileWatcher>();
	#end

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
	private static function createScriptWatcher(scriptDirectory:String, scriptName:String, onChanged:String->Void) {
		#if scriptable
		//
		// Create a FileWatcher to monitor the script file (the .cppia file)
		//
		//var scriptCppiaPath = Path.join([scriptDirectory, scriptName]); // programBasePath + "/" + scriptDirectory;
		//scriptCppiaPath = Path.normalize(scriptCppiaPath);

		scriptName = scriptName ?? "";		
		scriptDirectory = scriptDirectory ?? "";

		if (scriptName.length == 0) {
			Log.warn("No script name specified");
			return;
		}

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

		//var scriptCppiaFile = className + ".cppia";
		var scriptCppiaPath = getClassPath(scriptDirectory, scriptName);
		scriptCppiaPath = Path.join([Sys.getCwd(), scriptCppiaPath]); // programBasePath + "/../" + scriptDirectory;

		var cppiaFileWatcher = new FileWatcher(scriptCppiaPath, scriptCppiaFileFilter, (filename:String, event:FileEvent) -> {
			// wait for the file to be closed
			// Timer.delay(function() {

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
				//Log.warn("Script file added, ignoring: " + filename);
				onChanged(filename);
				return;
			}

			Log.info("Script file changed: " + filename);

			onChanged(filename);
		});

		cppiaFileWatcher.start();
		cppiaFileWatchers.set(scriptName, cppiaFileWatcher);
		#else
		Log.warn("ScriptWatcher not implemented for non-scriptable builds");
		#end
	}

	/**
	 * Create a FileWatcher to recompile script source file changes (.hx -> .cppia)
	 * @param scriptDirectory 
	 * @param scriptName 
	 * @param onLoaded 
	 */

	 private static function createScriptSourceWatcher(scriptDirectory:String, scriptName:String, scriptChangedCallback:String->Void) {
		// remove any existing haxe source file watchers
		#if scriptable
		if (haxeSourceFileWatchers.exists(scriptName)) {
			haxeSourceFileWatchers[scriptName].stop();
			haxeSourceFileWatchers.remove(scriptName);
		}

		// break the scriptName into the package name and class name
		var className = getClassName(scriptDirectory, scriptName);
		//var scriptSourceFile = className + ".hx";

		Log.info("Source path for script files(.hx) files is: " + scriptSourceDirectory);
		// Log.info("Source path for main files (.hx) files is: " + mainSourcePath);

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
		//Log.debug("scriptSourceFileFilter: " + scriptSourceFileFilter);

		var haxeSourceFileWatcher = new FileWatcher(scriptSourceDirectory, scriptSourceFileFilter, (filename:String, event:FileEvent) -> {
			//Log.debug("Script source file changed: " + filename);
			scriptChangedCallback(filename);
		});

		haxeSourceFileWatcher.start();
		haxeSourceFileWatchers.set(scriptName, haxeSourceFileWatcher);
		#else
		Log.warn("ScriptSourceWatcher not implemented for non-scriptable builds");
		#end
	}

	private static function createScriptInstance(scriptDirectory:String, className:String):Script {
		try {
			var resolvedClass = null;
			#if scriptable
			// allow env to override
			var scriptRuntimeDirectoryEnv = Sys.getEnv("SCRIPT_RUNTIME_PATH");
			scriptDirectory = scriptRuntimeDirectoryEnv ?? scriptDirectory;

			// check for the base script directory
			if (!FileSystem.exists(scriptDirectory)) {
				// Path.(scriptDirectory);
				var scriptAbsoluteDirectory = Path.join([Sys.getCwd(), scriptDirectory]);
				Log.error("Script directory not found: " + scriptAbsoluteDirectory);
				return null;
			}

			// Load the code from cppia file
			var sourceFilePath = Path.join([scriptDirectory, className + ".cppia"]);
			sourceFilePath = Path.normalize(sourceFilePath);
			if (!FileSystem.exists(sourceFilePath)) {
				Log.error("Script file not found: " + sourceFilePath);
				return null;
			}

			// create the module from the source file (.cppia)
			try {
				//Log.debug("Loading module: " + sourceFilePath);
				var source = sys.io.File.getBytes(sourceFilePath);
				var data = source.getData();
				if (data == null) {
					Log.error("Failed to load module (bad data): " + sourceFilePath);
					return null;
				}
				//Log.debug("Creating module from data: " + sourceFilePath);
				var module = Module.fromData(data);
				module.boot();
				//Log.debug("Running module: " + module);
				module.run(); // call main, if it exists?
				//Log.debug("Resolving class: " + className);
				resolvedClass = module.resolveClass(className);
				//Log.debug("Resolved class: " + resolvedClass);
			} catch (e) {
				Log.error("Failed to load module: " + sourceFilePath, "\n" + e.message);
				return null;
			}
			// Log.debug("Module: " + module);
			// Log.debug("Fields: " + fields);
			// Log.debug("Resolving class: " + scriptDirectory + '.' + className);
			// var resolvedClass:Class<Script> = cast module.resolveClass(className);
			// Log.debug("Class: " + this.scriptClass);
			#else
			//Log.debug("Resolving class: " + className);
			try {
				resolvedClass = Type.resolveClass(className);
				if (resolvedClass == null) {
					Log.error("Failed to resolve class: " + className);
					return null;
				}
			} catch(e) {
				Log.error("Failed to resolve class: " + className, "\n" + e.message);
				return null;
			}
			#end

			// make sure the class is derived from Script
			if (!TypeUtils.isDerivedFrom(resolvedClass, Script)) {
				Log.error('Class $className is not derived from Script');
				return null;
			}

			// create an instance of the class
			var script:Script = cast Type.createInstance(resolvedClass, []);
			if (script == null) {
				Log.error("Failed to create instance of class: " + className);
				return null;
			}

			// Reflect.setField(script, 'scriptName', className);
			// Reflect.setField(script, 'scriptDirectory', scriptDirectory);
			script.scriptName = className;
			script.scriptDirectory = scriptDirectory;

			// var fields = Type.getInstanceFields(Type.getClass(scriptHost));
			// var methods = fields.filter(field -> Reflect.isFunction(Reflect.field(scriptHost, field)));
			// Log.debug("Methods: " + methods.join(", "));

			//Log.debug("Created instance of class: " + className);

			return script;
		} catch (e:Dynamic) {
			Log.error("Unable to load script file: " + Std.string(e));
			return null;
		}
	}

	public static function load(scriptName:String, onLoaded:String->Script->Void):Void {
		var previousScript = scriptCache.get(scriptName);

		if (scriptCache.exists(scriptName)) {
			onLoaded(scriptName, scriptCache.get(scriptName));
			return;
		}

		// TODO: do we want to include the script directory as the package, or add the script directory class path when building?
		// var fullScriptName = scriptDirectory + '.' + scriptName;
		// var fullScriptName = scriptName;

		// Watch the script source.  If it changes, recompile.  
		createScriptSourceWatcher(scriptSourceDirectory, scriptName, (filename:String) -> {
			if (filename == null) {
				// we shouldn't get here, but just in case
				Log.error("Unknown script: " + scriptName);
				return;
			}

			//if (filename != scriptName) {
			//	Log.error('Script changed, but script name does not match: ${filename} != $scriptName');
			//	return;
			//}

			// var haxeArgs = ["--debug", "-dce", "no", "-lib", "hxcpp-debug-server" ];
			//var haxeArgs = ["-D", "CPPIA_NO_JIT"];
			
			var haxeArgs = ["-dce", "full"];

			var result = ScriptCompiler.compileScriptInternal("", scriptSourceDirectory, scriptDirectory, "cppia", haxeArgs, scriptName);

			if (result != 0) {
				// If the compilation failed, the script on disk will be the old version.
				// Should we call onLoaded(scriptName, null) if the compilation fails?
				//Log.error("Failed to compile script: " + scriptName);
				onLoaded(scriptName, null);
				return;
			}

		});

		// Watch for changes to the cppia file (the compiled script).  
		// If it changes, reload the script.
		createScriptWatcher(scriptDirectory, scriptName, (filename:String) -> {
			Log.info("Reloading script file: " + filename);

			if (filename == null) {
				return;
			}

			//if (filename != scriptName) {
			//	Log.error("Script file changed but name does not match: " + filename + " != " + scriptName);
			//	return;
			//}
			
			var changedScript = createScriptInstance(scriptDirectory, scriptName);
			onLoaded(scriptName,changedScript);
		});

		var script = createScriptInstance(scriptDirectory, scriptName);

		// save the script into our cache
		scriptCache.set(scriptName, script);

		if (script != null) {
			// successfully loaded
			onLoaded(scriptName, script);
		} else {
			Log.error('Error loading script: ' + scriptDirectory + '/' + scriptName);
			onLoaded(scriptName, null);
		}
		return;
	}
}
