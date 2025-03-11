package h3d.col;

@:native("h3d.col.PolygonBuffer") extern class PolygonBuffer extends h3d.col.Collider {
	function new():Void;
	var source : { var entry : hxd.fs.FileEntry; var geometryName : String; };
	function setData(buffer:haxe.ds.Vector<hxd.impl.Float32>, indexes:haxe.ds.Vector<Int>, ?startIndex:Int, ?triCount:Int):Void;
	function getBounds():h3d.col.Bounds;
	function getPoints():Array<h3d.col.FPoint>;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function dimension():Float;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function makeDebugObj():h3d.scene.Object;
}