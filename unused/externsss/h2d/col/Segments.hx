package h2d.col;

/**
 An abstract over the list of `Segment`s. Alternative representation of a polygon.
 
 Segments must be connected to form a complete polygonal shape.
 Provides a more efficient distance calculus.
 
 @see `h2d.Polygon`
 */
/**
	
		An abstract over the list of `Segment`s. Alternative representation of a polygon.
	
		Segments must be connected to form a complete polygonal shape.
		Provides a more efficient distance calculus.
	
		@see `h2d.Polygon`
	
**/
typedef Segments = Array<h2d.col.Segment>;