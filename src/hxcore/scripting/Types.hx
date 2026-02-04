package hxcore.scripting;

typedef ScriptContext = Dynamic;

typedef LoadedCallback = (scriptName:String, scriptInfo:ScriptInfo) -> Void;

typedef ScriptInfo = {
	var ?className:String;
	var ?script:Script;
	var ?loadedCallback:LoadedCallback;
	var ?isExternal:Bool;
	var ?sourcePath:String;
}

enum HotCompileScope {
	ScriptOnly;
	SourceRoot;
}
