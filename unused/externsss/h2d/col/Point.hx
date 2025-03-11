package h2d.col;

/**
 A simple 2D position/vector container.
 @see `h2d.col.IPoint`
 */
/**
	
		A simple 2D position/vector container.
		@see `h2d.col.IPoint`
	
**/
@:native("h2d.col.Point") extern class PointImpl {
	/**
		
				The horizontal position of the point.
			
	**/
	var x : Float;
	/**
		
				The vertical position of the point.
			
	**/
	var y : Float;
	@:dox(hide)
	function toString():String;
}

@:forward typedef Point = h2d.col.Point.PointImpl;