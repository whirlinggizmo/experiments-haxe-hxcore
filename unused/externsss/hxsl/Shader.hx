package hxsl;

@:autoBuild(hxsl.Macros.buildShader()) @:native("hxsl.Shader") extern class Shader {
	function new():Void;
	var priority(default, null) : Int;
	/**
		
				Shader priority should only be changed *before* the shader is added to a material.
			
	**/
	function setPriority(v:Int):Void;
	function getParamValue(index:Int):Dynamic;
	function getParamFloatValue(index:Int):Float;
	function setParamIndexValue(index:Int, val:Dynamic):Void;
	function setParamIndexFloatValue(index:Int, val:Float):Void;
	function updateConstants(globals:Dynamic):Void;
	function clone():hxsl.Shader;
	function toString():String;
}