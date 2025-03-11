package h2d.col;

/**
 A 2D line segment.
 @see `h2d.Segments`
 */
/**
	
		A 2D line segment.
		@see `h2d.Segments`
	
**/
@:native("h2d.col.Segment") extern class Segment {
	/**
		
				X starting position of the Segment.
		
				Please use `Segment.setPoints` to modify this value.
			
	**/
	var x : Float;
	/**
		
				Y starting position of the Segment.
		
				Please use `Segment.setPoints` to modify this value.
			
	**/
	var y : Float;
	/**
		
				The delta-value of X end position of the Segment relative to starting position.
		
				Please use `Segment.setPoints` to modify this value.
			
	**/
	var dx : Float;
	/**
		
				The delta-value of Y end position of the Segment relative to starting position.
		
				Please use `Segment.setPoints` to modify this value.
			
	**/
	var dy : Float;
	/**
		
				Squared length of the segment.
		
				Please use `Segment.setPoints` to modify this value.
			
	**/
	var lenSq : Float;
	/**
		
				Inverse of the Segments squared length.
		
				Please use `Segment.setPoints` to modify this value.
			
	**/
	var invLenSq : Float;
}