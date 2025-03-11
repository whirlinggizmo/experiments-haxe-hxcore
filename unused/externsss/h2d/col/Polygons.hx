package h2d.col;

/**
 An abstract over an Array of `Polygon` instances that define multiple polygonal shapes that can be collision-tested against.
 @see `h2d.IPolygons`
 */
/**
	
		An abstract over an Array of `Polygon` instances that define multiple polygonal shapes that can be collision-tested against.
		@see `h2d.IPolygons`
	
**/
@:forward(push, remove) typedef Polygons = Array<h2d.col.Polygon>;