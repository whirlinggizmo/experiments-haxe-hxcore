package h3d.col;

@:native("h3d.col.Frustum") extern class Frustum {
	function new(?mvp:h3d.Matrix):Void;
	var pleft : h3d.col.Plane;
	var pright : h3d.col.Plane;
	var ptop : h3d.col.Plane;
	var pbottom : h3d.col.Plane;
	var pnear : h3d.col.Plane;
	var pfar : h3d.col.Plane;
	var checkNearFar : Bool;
	function clone():h3d.col.Frustum;
	function loadMatrix(mvp:h3d.Matrix):Void;
	function transform(m:h3d.Matrix):Void;
	function transform3x3(m:h3d.Matrix):Void;
	function hasPoint(p:h3d.col.Point):Bool;
	function hasSphere(s:h3d.col.Sphere):Bool;
	function hasBounds(b:h3d.col.Bounds):Bool;
	function hasOrientedBounds(b:h3d.col.OrientedBounds):Bool;
}