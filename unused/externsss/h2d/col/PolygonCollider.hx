package h2d.col;

/**
 A `Collider` wrapper around `Polygons` to enable using those for hit-testing testing.
 */
/**
	
		A `Collider` wrapper around `Polygons` to enable using those for hit-testing testing.
	
**/
@:native("h2d.col.PolygonCollider") extern class PolygonCollider extends h2d.col.Collider {
	/**
		
				Create new PolygonCollider with specified Polygons and flag to check as convex or concave.
			
	**/
	function new(polygons:h2d.col.Polygons, ?isConvex:Bool):Void;
	/**
		
				The Polygons instance used for collision checks.
			
	**/
	var polygons : h2d.col.Polygons;
	/**
		
				Whether Polygons is convex or concave.
				Convex polygons are cheaper to test against.
			
	**/
	var isConvex : Bool;
	/**
		
				Test is Point `p` is inside `polygons`.
			
	**/
	override function contains(p:h2d.col.Point):Bool;
	override function collideCircle(c:h2d.col.Circle):Bool;
	override function collideBounds(b:h2d.col.Bounds):Bool;
}