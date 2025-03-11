package h3d.col;

@:native("h3d.col.Collider") extern class Collider {
	/**
		
				Returns the distance of intersection between the ray and the collider, or negative if no collision.
				If bestMatch is false, only negative/positive value needs to be returned, with no additional precision.
			
	**/
	function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	function contains(p:h3d.col.Point):Bool;
	function inFrustum(f:h3d.col.Frustum, ?localMatrix:h3d.Matrix):Bool;
	function inSphere(s:h3d.col.Sphere):Bool;
	function dimension():Float;
	function closestPoint(p:h3d.col.Point):h3d.col.Point;
	function makeDebugObj():h3d.scene.Object;
}

@:native("h3d.col.Collider") extern class OptimizedCollider extends h3d.col.Collider {
	function new(a:h3d.col.Collider, b:h3d.col.Collider):Void;
	var a : h3d.col.Collider;
	var b : h3d.col.Collider;
	var checkInside : Bool;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function dimension():Float;
	override function closestPoint(p:h3d.col.Point):h3d.col.Point;
	override function makeDebugObj():h3d.scene.Object;
}

@:native("h3d.col.Collider") extern class GroupCollider extends h3d.col.Collider {
	function new(colliders:Array<h3d.col.Collider>):Void;
	var colliders : Array<h3d.col.Collider>;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function dimension():Float;
	override function closestPoint(p:h3d.col.Point):h3d.col.Point;
	override function makeDebugObj():h3d.scene.Object;
}