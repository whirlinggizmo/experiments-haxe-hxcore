package h3d.col;

@:allow(h3d.col) @:native("h3d.col.Plane") extern class Plane {
	function transform(m:h3d.Matrix):Void;
	function transform3x3(m:h3d.Matrix):Void;
	function toString():String;
}