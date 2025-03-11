package h3d.col;

@:native("h3d.col.Seg") extern class Seg {
	var p1 : h3d.col.Point;
	var p2 : h3d.col.Point;
	var lenSq : Float;
	function toString():String;
}