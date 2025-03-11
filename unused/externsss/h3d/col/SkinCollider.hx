package h3d.col;

@:access(h3d.col.PolygonBuffer) @:access(h3d.scene.Skin) @:native("h3d.col.SkinCollider") extern class SkinCollider extends h3d.col.Collider {
	function new(obj:h3d.scene.Skin, col:h3d.col.PolygonBuffer):Void;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(p:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function dimension():Float;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function makeDebugObj():h3d.scene.Object;
}

@:access(h3d.col.SkinCollider) @:access(h3d.scene.Skin) @:native("h3d.col.SkinCollider") extern class SkinColliderDebugObj extends h3d.scene.Object {
	function new(col:h3d.col.SkinCollider):Void;
}