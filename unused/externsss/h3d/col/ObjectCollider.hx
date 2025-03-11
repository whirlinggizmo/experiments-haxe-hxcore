package h3d.col;

@:native("h3d.col.ObjectCollider") extern class ObjectCollider extends h3d.col.Collider {
	function new(obj:h3d.scene.Object, collider:h3d.col.Collider):Void;
	var obj : h3d.scene.Object;
	var collider : h3d.col.Collider;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function makeDebugObj():h3d.scene.Object;
}