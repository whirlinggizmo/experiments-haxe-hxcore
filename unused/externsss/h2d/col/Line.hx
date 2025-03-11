package h2d.col;

/**
 An infinite 2D line going through two specified Points.
 */
/**
	
		An infinite 2D line going through two specified Points.
	
**/
@:native("h2d.col.Line") extern class Line {
	/**
		
				The first line point.
			
	**/
	var p1 : h2d.col.Point;
	/**
		
				The second line point.
			
	**/
	var p2 : h2d.col.Point;
}