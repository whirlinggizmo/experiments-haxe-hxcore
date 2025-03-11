package h3d;

typedef ColorAdjust = {
	@:optional
	var contrast : Float;
	@:optional
	var gain : { public var color(default, default) : Int; public var alpha(default, default) : Float; };
	@:optional
	var hue : Float;
	@:optional
	var lightness : Float;
	@:optional
	var saturation : Float;
};

@:native("h3d.Matrix") extern class MatrixImpl {
	var _11 : Float;
	var _12 : Float;
	var _13 : Float;
	var _14 : Float;
	var _21 : Float;
	var _22 : Float;
	var _23 : Float;
	var _24 : Float;
	var _31 : Float;
	var _32 : Float;
	var _33 : Float;
	var _34 : Float;
	var _41 : Float;
	var _42 : Float;
	var _43 : Float;
	var _44 : Float;
	var tx(get, set) : Float;
	var ty(get, set) : Float;
	var tz(get, set) : Float;
	function equal(other:h3d.Matrix):Bool;
	function zero():Void;
	function identity():Void;
	function isIdentity():Bool;
	function isIdentityEpsilon(e:Float):Bool;
	function initRotationX(a:Float):Void;
	function initRotationY(a:Float):Void;
	function initRotationZ(a:Float):Void;
	function initTranslation(?x:Float, ?y:Float, ?z:Float):Void;
	function initScale(?x:Float, ?y:Float, ?z:Float):Void;
	function initRotationAxis(axis:h3d.Vector, angle:Float):Void;
	function initRotation(x:Float, y:Float, z:Float):Void;
	function translate(?x:Float, ?y:Float, ?z:Float):Void;
	function scale(?x:Float, ?y:Float, ?z:Float):Void;
	function rotate(x:Float, y:Float, z:Float):Void;
	function rotateAxis(axis:h3d.Vector, angle:Float):Void;
	function prependTranslation(?x:Float, ?y:Float, ?z:Float):Void;
	function prependRotation(x:Float, y:Float, z:Float):Void;
	function prependRotationAxis(axis:h3d.Vector, angle:Float):Void;
	function prependScale(?sx:Float, ?sy:Float, ?sz:Float):Void;
	@:noDebug
	function multiply3x4(a:h3d.Matrix, b:h3d.Matrix):Void;
	function multiply(a:h3d.Matrix, b:h3d.Matrix):Void;
	function multiplyValue(v:Float):Void;
	function getInverse(?m:h3d.Matrix):h3d.Matrix;
	function inverse3x4(m:h3d.Matrix):Void;
	function initInverse(m:h3d.Matrix):Void;
	function initInverse3x3(m:h3d.Matrix):Void;
	function transpose():Void;
	function clone():h3d.Matrix;
	function load(m:h3d.Matrix):Void;
	function loadValues(a:Array<Float>):Void;
	function getFloats():Array<Float>;
	function getDirection():h3d.Vector;
	/**
		
				Extracts Euler rotation angles from rotation matrix
			
	**/
	function getEulerAngles():h3d.Vector;
	function toString():String;
	function colorHue(hue:Float):Void;
	function colorSaturate(sat:Float):Void;
	function colorContrast(contrast:Float):Void;
	function colorLightness(lightness:Float):Void;
	function colorGain(color:Int, alpha:Float):Void;
	function colorBits(bits:Int, blend:Float):Void;
	function adjustColor(col:h3d.Matrix.ColorAdjust):Void;
	/**
		
				Extract the rotation from `inMatrix` and stores it as a quaternion inside the [m12,m13,m21,m23] component
				instead of the rotation being mixed with the scale.
			
	**/
	function decomposeMatrix(inMatrix:h3d.Matrix):Void;
	/**
		
				Inverts the operation of `decomposeMatrix`, giving back a normal transformation matrix from a decomposed one
			
	**/
	function recomposeMatrix(inMatrix:h3d.Matrix):Void;
}

@:forward typedef Matrix = h3d.Matrix.MatrixImpl;