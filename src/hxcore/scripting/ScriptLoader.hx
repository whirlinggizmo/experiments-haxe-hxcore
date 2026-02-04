package hxcore.scripting;

import hxcore.logging.Log;
import hxcore.scripting.ScriptResolution;
import hxcore.scripting.Types.HotCompileScope;
import hxcore.scripting.Types.ScriptInfo;

class ScriptLoader implements IScriptLoader {
	public function new() {}

	public function setOverrideMode(mode:ScriptResolution.OverrideMode):Void {}
	public function setChangeDebounceMs(ms:Int):Void {}
	public function setScriptDirectory(dir:String):Void {}
	public function setScriptSourceDirectory(dir:String):Void {}
	public function setExternalEnabled(enable:Bool, ?scriptDirectory:String):Void {}
	public function setHotReloadEnabled(enable:Bool):Void {}
	public function setHotCompileEnabled(enable:Bool, ?scriptSourceDirectory:String):Void {}
	public function setHotCompileScope(scope:HotCompileScope):Void {}
	public function tickWatchers():Void {}

	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void {
		Log.warn("ScriptLoader is not implemented for this target.");
		if (onLoaded != null) {
			onLoaded(scriptName, null);
		}
	}

	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void {
		Log.warn("ScriptLoader is not implemented for this target.");
		if (onLoaded != null) {
			onLoaded(scriptName, null);
		}
	}

	public function unload(scriptName:String):Void {}
	public function dispose():Void {}
}
