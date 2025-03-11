package h3d.col;

@:native("h3d.col.OrientedBounds") extern class OrientedBounds extends h3d.col.Collider {
	function new():Void;
	var centerX : Float;
	var centerY : Float;
	var centerZ : Float;
	var xx : Float;
	var xy : Float;
	var xz : Float;
	var yx : Float;
	var yy : Float;
	var yz : Float;
	var zx : Float;
	var zy : Float;
	var zz : Float;
	var hx : Float;
	var hy : Float;
	var hz : Float;
	function setMatrix(m:h3d.Matrix):Void;
	function setEulerAngles(x:Float, y:Float, z:Float):Void;
	function collideOrientedBounds(other:h3d.col.OrientedBounds):Bool;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function contains(p:h3d.col.Point):Bool;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function dimension():Float;
	function getVertices(?out:Array<h3d.Vector>):Array<h3d.Vector>;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function makeDebugObj():h3d.scene.Graphics;
}