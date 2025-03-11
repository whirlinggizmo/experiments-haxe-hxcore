package h3d;

/**
 A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
 */
/**
	
		A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
	
**/
@:native("h3d.Vector4") extern class Vector4Impl {
	var x : Float;
	var y : Float;
	var z : Float;
	var w : Float;
	function toString():String;
	var r(get, set) : Float;
	var g(get, set) : Float;
	var b(get, set) : Float;
	var a(get, set) : Float;
	function makeColor(hue:Float, ?saturation:Float, ?brightness:Float):Void;
	function toColorHSL():h3d.Vector4;
	function toColorHSV():h3d.Vector4;
}

/**
 A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
 For function manipulating the length (length, normalize, dot, scale, etc.), the Vector
 acts like a Point in the sense only the X/Y/Z components will be affected.
 */
/**
	
		A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
		For function manipulating the length (length, normalize, dot, scale, etc.), the Vector
		acts like a Point in the sense only the X/Y/Z components will be affected.
	
**/
@:forward typedef Vector4 = h3d.Vector4.Vector4Impl;