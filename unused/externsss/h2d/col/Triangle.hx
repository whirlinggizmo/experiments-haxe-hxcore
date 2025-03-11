package h2d.col;

/**
 A simple triangle collider.
 */
/**
	
		A simple triangle collider.
	
**/
@:native("h2d.col.Triangle") extern class Triangle extends h2d.col.Collider {
	/**
		
				The triangle first corner.
			
	**/
	var a : h2d.col.Point;
	/**
		
				The triangle second corner.
			
	**/
	var b : h2d.col.Point;
	/**
		
				The triangle third corner.
			
	**/
	var c : h2d.col.Point;
	/**
		
				Tests if Point `p` is inside this Triangle.
			
	**/
	override function contains(p:h2d.col.Point):Bool;
	override function collideCircle(c:h2d.col.Circle):Bool;
	override function collideBounds(b:h2d.col.Bounds):Bool;
}