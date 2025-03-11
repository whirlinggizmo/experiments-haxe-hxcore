package h2d.col;

/**
 A Collider representing the rectangle with the rounded edges, forming a 2D capsule.
 */
/**
	
		A Collider representing the rectangle with the rounded edges, forming a 2D capsule.
	
**/
@:native("h2d.col.RoundRect") extern class RoundRect extends h2d.col.Collider {
	/**
		
				The horizontal position of the rectangle center.
			
	**/
	var x : Float;
	/**
		
				The vertical position of the rectangle center.
			
	**/
	var y : Float;
	/**
		
				Tests is given Point `p` is inside the capsule area.
			
	**/
	override function contains(p:h2d.col.Point):Bool;
	override function collideCircle(c:h2d.col.Circle):Bool;
	override function collideBounds(b:h2d.col.Bounds):Bool;
}