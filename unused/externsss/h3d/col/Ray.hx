package h3d.col;

@:allow(h3d.col) @:native("h3d.col.Ray") extern class Ray {
	var px : Float;
	var py : Float;
	var pz : Float;
	var lx : Float;
	var ly : Float;
	var lz : Float;
	function toString():String;
}