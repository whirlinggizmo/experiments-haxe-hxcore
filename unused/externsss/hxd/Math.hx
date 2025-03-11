package hxd;

@:native("hxd.Math") extern class Math {
	static var PI(default, never) : Float;
	static var EPSILON(default, never) : Float;
	static var EPSILON2(default, never) : Float;
	static var POSITIVE_INFINITY(get, never) : Float;
	static var NEGATIVE_INFINITY(get, never) : Float;
	static var NaN(get, never) : Float;
	static function fmt(v:Float):Float;
	/**
		
				Linear interpolation between two colors (ARGB).
			
	**/
	static function colorLerp(c1:Int, c2:Int, k:Float):Int;
	/**
		
				Returns a signed random between -max and max (both included).
			
	**/
	static function srand(?max:Float):Float;
}