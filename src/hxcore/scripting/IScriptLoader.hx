package hxcore.scripting;

import hxcore.scripting.Types.ScriptInfo;
import hxcore.scripting.Types.HotCompileScope;

interface IScriptLoader {
	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void;
	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void;
	public function unload(scriptName:String):Void;
	public function dispose():Void;

	public function setScriptDirectory(dir:String):Void;
	public function setScriptSourceDirectory(dir:String):Void;
	public function setOverrideMode(mode:ScriptResolution.OverrideMode):Void;
	public function setChangeDebounceMs(ms:Int):Void;
	public function setExternalEnabled(enable:Bool, ?scriptDirectory:String):Void;
	public function setHotReloadEnabled(enable:Bool):Void;
	public function setHotCompileEnabled(enable:Bool, ?scriptSourceDirectory:String):Void;
	public function setHotCompileScope(scope:HotCompileScope):Void;
	public function tickWatchers():Void;
}
