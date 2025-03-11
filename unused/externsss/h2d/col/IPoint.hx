package h2d.col;

/**
 An integer-based point.
 @see `h2d.col.Point`
 */
/**
	
		An integer-based point.
		@see `h2d.col.Point`
	
**/
@:native("h2d.col.IPoint") extern class IPoint {
	/**
		
				Horizontal position of the point.
			
	**/
	var x : Int;
	/**
		
				Vertical position of the point.
			
	**/
	var y : Int;
	@:dox(hide)
	function toString():String;
}