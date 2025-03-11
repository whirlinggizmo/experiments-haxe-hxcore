package h2d.col;

/**
 An abstract around an Array of `Point`s that define a polygonal shape that can be collision-tested against.
 @see `h2d.col.IPolygon`
 */
/**
	
		An abstract around an Array of `Point`s that define a polygonal shape that can be collision-tested against.
		@see `h2d.col.IPolygon`
	
**/
@:forward(push, remove, insert, copy) typedef Polygon = Array<h2d.col.Point>;