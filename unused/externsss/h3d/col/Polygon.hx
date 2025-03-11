package h3d.col;

@:allow(h3d.col.Polygon) @:native("h3d.col.Polygon") extern class TriPlane extends h3d.col.Collider {
	function new(?o:Bool):Void;
	var next : h3d.col.Polygon.TriPlane;
	function transform(m:h3d.Matrix):Void;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	function getPoints():Array<h3d.col.Point>;
	override function makeDebugObj():h3d.scene.Object;
	override function dimension():Float;
}

@:native("h3d.col.Polygon") extern class Polygon extends h3d.col.Collider {
	function new(?o:Bool):Void;
	function addBuffers(vertexes:haxe.ds.Vector<hxd.impl.Float32>, indexes:haxe.ds.Vector<Int>, ?stride:Int):Void;
	function isConvex():Bool;
	function clone():h3d.col.Polygon;
	function transform(m:h3d.Matrix):Void;
	function getPoints():Array<h3d.col.Point>;
	function getBounds(?bnds:h3d.col.Bounds):h3d.col.Bounds;
	override function contains(p:h3d.col.Point):Bool;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function makeDebugObj():h3d.scene.Object;
	static function fromPolygon2D(p:h2d.col.Polygon, ?z:Float, ?oriented:Bool):h3d.col.Polygon;
}