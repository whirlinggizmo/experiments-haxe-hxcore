package h2d.col;

/**
 The resulting triangle of a Delaunay triangulation operation.
 @see `Delaunay.triangulate`
 */
/**
	
		The resulting triangle of a Delaunay triangulation operation.
		@see `Delaunay.triangulate`
	
**/
@:native("h2d.col.Delaunay") extern class DelaunayTriangle {
	/**
		 Create a new Delaunay result triangle. 
	**/
	function new(p1:h2d.col.Point, p2:h2d.col.Point, p3:h2d.col.Point):Void;
	/**
		 First vertex of the triangle. 
	**/
	var p1 : h2d.col.Point;
	/**
		 Second vertex of the triangle. 
	**/
	var p2 : h2d.col.Point;
	/**
		 Third vertex of the triangle. 
	**/
	var p3 : h2d.col.Point;
}

/**
 A Delaunay triangulation utility. See `Delaunay.triangulate`.
 */
/**
	
		A Delaunay triangulation utility. See `Delaunay.triangulate`.
	
**/
@:native("h2d.col.Delaunay") extern class Delaunay {
	/**
		
				Performs a Delaunay triangulation on a given set of Points and returns a list of calculated triangles.
				See here for more information: https://en.wikipedia.org/wiki/Delaunay_triangulation
			
	**/
	static function triangulate(points:Array<h2d.col.Point>):Array<h2d.col.Delaunay.DelaunayTriangle>;
}