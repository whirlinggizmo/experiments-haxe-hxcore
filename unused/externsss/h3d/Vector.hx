package h3d;

/**
 A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
 */
/**
	
		A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
	
**/
@:native("h3d.Vector") extern class VectorImpl {
	var x : Float;
	var y : Float;
	var z : Float;
	function toString():String;
	var r(get, set) : Float;
	var g(get, set) : Float;
	var b(get, set) : Float;
	function makeColor(hue:Float, ?saturation:Float, ?brightness:Float):Void;
	function toColorHSL():h3d.Vector;
	function toColorHSV():h3d.Vector;
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
@:forward typedef Vector = h3d.Vector.VectorImpl;