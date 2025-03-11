package h3d.col;

/**
 This is an helper class to define a heightmap-based collider.
 In order to use, you need to extends this class and override the getZ method
 in order to return appropriate Z value based on X and Y coordinates.
 */
/**
	
		This is an helper class to define a heightmap-based collider.
		In order to use, you need to extends this class and override the getZ method
		in order to return appropriate Z value based on X and Y coordinates.
	
**/
@:native("h3d.col.HeightMap") extern class HeightMap extends h3d.col.Collider {
	/**
		
				When performing raycast check, tells by how much step we advance.
				If this is too small, raycast check will be too expensive.
				If this is too big, we might step through a hip without noticing.
				Default : 1.0
			
	**/
	var step : Float;
	/**
		
				Tells which precision is required for the result.
				We will iterate until we have reach the given precision.
			
	**/
	var precision : Float;
	override function inFrustum(f:h3d.col.Frustum, ?m:h3d.Matrix):Bool;
	override function inSphere(s:h3d.col.Sphere):Bool;
	override function closestPoint(sp:h3d.col.Point):h3d.col.Point;
	override function rayIntersection(r:h3d.col.Ray, bestMatch:Bool):Float;
	override function makeDebugObj():h3d.scene.Object;
}