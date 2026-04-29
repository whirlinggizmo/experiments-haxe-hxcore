package hxcore.scripting;

import hxcore.scripting.ScriptConfig.HotCompileScope;

typedef ScriptInfo = {
	var ?className:String;
	var ?script:Script;
	var ?loadedCallback:(scriptName:String, scriptInfo:ScriptInfo) -> Void;
	var ?isExternal:Bool;
	var ?sourcePath:String;
}

interface IScriptLoader {
	public function load(scriptName:String, onLoaded:String->ScriptInfo->Void):Void;
	public function forceReload(scriptName:String, ?onLoaded:String->ScriptInfo->Void):Void;
	public function unload(scriptName:String):Void;
	public function isLoaded(scriptName:String):Bool;
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
