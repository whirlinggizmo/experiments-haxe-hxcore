package h2d.col;

/**
 A common interface for 2D Shapes to hit-test again the mouse or a specific point in space.
 */
/**
	
		A common interface for 2D Shapes to hit-test again the mouse or a specific point in space.
	
**/
@:native("h2d.col.Collider") extern class Collider {
	/**
		
				Tests if Point `p` is inside the Collider.
			
	**/
	function contains(p:h2d.col.Point):Bool;
	function collideCircle(c:h2d.col.Circle):Bool;
	function collideBounds(b:h2d.col.Bounds):Bool;
}