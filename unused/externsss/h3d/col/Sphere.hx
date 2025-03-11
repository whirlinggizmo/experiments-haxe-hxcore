package h3d.col;

@:native("h3d.col.Sphere") extern class Sphere extends h3d.col.Collider {
	var x : Float;
	var y : Float;
	var z : Float;
	var r : Float;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	function transform(m:h3d.Matrix):Void;
	function toString():String;
	override function makeDebugObj():h3d.scene.Object;
}