package h2d.col;

/**
 The resulting cell inside the Voronoi diagram.
 */
/**
	
		The resulting cell inside the Voronoi diagram.
	
**/
@:native("h2d.col.Voronoi") extern class Cell {
	@:dox(hide)
	@:noCompletion
	function new(id:Int, point:h2d.col.Point):Void;
	/**
		
				The unique ID/Index of the cell.
			
	**/
	var id : Int;
	/**
		
				The source seed point of the cell.
			
	**/
	var point : h2d.col.Point;
	/**
		
				The list of the edges of the cell.
			
	**/
	var halfedges : Array<h2d.col.Voronoi.Halfedge>;
	var closeMe : Bool;
	/**
		
				Returns an enclosing circle collider of the Cell.
		
				_Implementation note_: Not the best possible solution and may produce artifacts.
			
	**/
	function getCircle():h2d.col.Circle;
	@:dox(hide)
	@:noCompletion
	function prepare():Int;
	/**
		
				Returns a list of the neighboring cells.
			
	**/
	function getNeighbors():Array<h2d.col.Point>;
	/**
		
				Returns a list of the neighbor Cell indexes.
			
	**/
	function getNeighborIndexes():Array<Int>;
	/**
		
				Returns a bounding box of the Cell.
			
	**/
	function getBbox():{ var height : Float; var width : Float; var x : Float; var y : Float; };
	/**
		
				Tests if given position is inside, on, or outside of the cell.
				@returns
				* -1: point is outside the perimeter of the cell
				* 0: point is on the perimeter of the cell
				* 1: point is inside the perimeter of the cell
			
	**/
	function pointIntersection(x:Float, y:Float):Int;
}

/**
 The resulting edge inside the Voronoi diagram.
 */
/**
	
		The resulting edge inside the Voronoi diagram.
	
**/
@:native("h2d.col.Voronoi") extern class Edge {
	@:dox(hide)
	@:noCompletion
	function new(lPoint:h2d.col.Point, rPoint:h2d.col.Point):Void;
	/**
		
				The unique ID/Index of the edge.
			
	**/
	var id : Int;
	/**
		
				The left-hand seed point.
			
	**/
	var lPoint : h2d.col.Point;
	/**
		
				The right-hand seed point.
			
	**/
	var rPoint : h2d.col.Point;
	/**
		
				The left-hand cell along the edge.
			
	**/
	var lCell : h2d.col.Voronoi.Cell;
	/**
		
				The right-hand cell along the edge.
			
	**/
	var rCell : h2d.col.Voronoi.Cell;
	/**
		
				The first position of the edge segment.
			
	**/
	var va : h2d.col.Point;
	/**
		
				The second position of the edge segment.
			
	**/
	var vb : h2d.col.Point;
}

/**
 The edge attached to a Voronoi `Cell`.
 */
/**
	
		The edge attached to a Voronoi `Cell`.
	
**/
@:native("h2d.col.Voronoi") extern class Halfedge {
	@:dox(hide)
	@:noCompletion
	function new(edge:h2d.col.Voronoi.Edge, lPoint:h2d.col.Point, rPoint:h2d.col.Point):Void;
	/**
		
				The seed Point of the Cell this edge is attached to.
			
	**/
	var point : h2d.col.Point;
	/**
		
				The Edge this half-edge is attached to.
			
	**/
	var edge : h2d.col.Voronoi.Edge;
	/**
		
				The perpendicular angle to the edge segment pointing in the direction of either neighboring Cell of the border.
			
	**/
	var angle : Float;
}

/**
 The resulting diagram of the `Voronoi.compute`.
 */
/**
	
		The resulting diagram of the `Voronoi.compute`.
	
**/
@:native("h2d.col.Voronoi") extern class Diagram {
	@:dox(hide)
	@:noCompletion
	function new():Void;
	/**
		
				The list of the generated cells.
			
	**/
	var cells : Array<h2d.col.Voronoi.Cell>;
	/**
		
				The list of the diagram seed points.
			
	**/
	var points : Array<h2d.col.Point>;
	/**
		
				The list of edges between diagram cells.
			
	**/
	var edges : Array<h2d.col.Voronoi.Edge>;
	/**
		
				The duration it took to compute this diagram.
			
	**/
	var execTime : Float;
}

/**
 A Steven Fortune's algorithm to compute Voronoi diagram from given set of Points and a bounding box.
 
 The implementation is a port from JS library: https://github.com/gorhill/Javascript-Voronoi
 */
/**
	
		A Steven Fortune's algorithm to compute Voronoi diagram from given set of Points and a bounding box.
	
		The implementation is a port from JS library: https://github.com/gorhill/Javascript-Voronoi
	
**/
@:native("h2d.col.Voronoi") extern class Voronoi {
	/**
		
				Create a new Voronoi algorithm calculator.
			
	**/
	function new(?epsilon:Float):Void;
	/**
		
				Clean up the calculator from previous operation, and prepare for a new one.
		
				Not required to be called manually, as it's invoked by `Voronoi.compute`.
			
	**/
	function reset():Void;
	/**
		
				Compute the Voronoi diagram based on given list of points and bounding box.
			
	**/
	function compute(points:Array<h2d.col.Point>, bbox:h2d.col.Bounds):h2d.col.Voronoi.Diagram;
}