package h2d.col;

/**
 The type of the edges when offsetting polygon with `IPolygon.offset`.
 */
/**
	
		The type of the edges when offsetting polygon with `IPolygon.offset`.
	
**/
@:native("h2d.col.IPolygon") extern enum OffsetKind {
	Square;
	Miter;
	Round(arc:Float);
}

/**
 An abstract around an Array of `IPoint`s that define a polygonal shape that can be collision-tested against.
 @see `h2d.col.Polygon`
 */
/**
	
		An abstract around an Array of `IPoint`s that define a polygonal shape that can be collision-tested against.
		@see `h2d.col.Polygon`
	
**/
@:forward(push, remove, insert, copy) typedef IPolygon = Array<h2d.col.IPoint>;