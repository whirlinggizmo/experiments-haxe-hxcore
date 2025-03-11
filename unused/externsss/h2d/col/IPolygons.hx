package h2d.col;

/**
 An abstract over an Array of `IPolygon` instances that define multiple polygonal shapes that can be collision-tested against.
 @see `h2d.Polygons`
 */
/**
	
		An abstract over an Array of `IPolygon` instances that define multiple polygonal shapes that can be collision-tested against.
		@see `h2d.Polygons`
	
**/
@:forward(push, remove) typedef IPolygons = Array<h2d.col.IPolygon>;