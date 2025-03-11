package h3d.col;

@:native("h3d.col.TransformCollider") extern class TransformCollider extends h3d.col.Collider {
	function new(mat:h3d.Matrix, collider:h3d.col.Collider):Void;
	var collider : h3d.col.Collider;
	var mat(default, set) : h3d.Matrix;
	private function set_mat(m:h3d.Matrix):h3d.Matrix;
	function transform(m:h3d.Matrix):h3d.col.TransformCollider;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function dimension():Float;
	override function closestPoint(p:h3d.col.Point):h3d.col.Point;
	override function makeDebugObj():h3d.scene.Object;
	static function make(mat:h3d.Matrix, col:h3d.col.Collider):h3d.col.Collider;
}