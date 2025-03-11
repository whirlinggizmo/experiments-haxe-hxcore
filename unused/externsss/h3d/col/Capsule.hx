package h3d.col;

@:native("h3d.col.Capsule") extern class Capsule extends h3d.col.Collider {
	var a : h3d.col.Point;
	var b : h3d.col.Point;
	var r : Float;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	function toString():String;
	override function dimension():Float;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function makeDebugObj():h3d.scene.Object;
}