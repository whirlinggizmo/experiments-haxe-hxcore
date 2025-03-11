package h3d.col;

@:native("h3d.col.Bounds") extern class Bounds extends h3d.col.Collider {
	var xMin : Float;
	var xMax : Float;
	var yMin : Float;
	var yMax : Float;
	var zMin : Float;
	var zMax : Float;
	var xSize(get, set) : Float;
	var ySize(get, set) : Float;
	var zSize(get, set) : Float;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	/**
		
			 * Check if the camera model-view-projection Matrix intersects with the Bounds. Returns -1 if outside, 0 if intersects and 1 if fully inside.
			 * @param	mvp : the model-view-projection matrix to test against
			 * @param	checkZ : tells if we will check against the near/far plane
			 
	**/
	function inFrustumDetails(mvp:h3d.Matrix, ?checkZ:Bool):Int;
	function transform3x3(m:h3d.Matrix):Void;
	function transform(m:h3d.Matrix):Void;
	function intersection(a:h3d.col.Bounds, b:h3d.col.Bounds):Void;
	function load(b:h3d.col.Bounds):Void;
	function scaleCenter(v:Float):Void;
	function toString():String;
	override function closestPoint(p:h3d.col.Point):h3d.Vector;
	override function makeDebugObj():h3d.scene.Object;
}