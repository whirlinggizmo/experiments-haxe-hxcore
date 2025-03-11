package h2d.col;

/**
 The circular hitbox implementation of a 2D Collider.
 */
/**
	
		The circular hitbox implementation of a 2D Collider.
	
**/
@:native("h2d.col.Circle") extern class Circle extends h2d.col.Collider {
	/**
		
				Horizontal position of the Circle center.
			
	**/
	var x : Float;
	/**
		
				Vertical position of the Circle center.
			
	**/
	var y : Float;
	/**
		
				Radius of the circle.
			
	**/
	var ray : Float;
	@:dox(hide)
	function toString():String;
	/**
		
				Tests if Point `p` is inside this Circle.
			
	**/
	override function contains(p:h2d.col.Point):Bool;
}