package h2d.col;

/**
 A 2D bounding box often used for determining Object bounding area.
 
 Bounds holds min/max coordinates of bounding box instead of it's position and size.
 @see `Object.getBounds`
 @see `Object.getSize`
 */
/**
	
		A 2D bounding box often used for determining Object bounding area.
	
		Bounds holds min/max coordinates of bounding box instead of it's position and size.
		@see `Object.getBounds`
		@see `Object.getSize`
	
**/
@:native("h2d.col.Bounds") extern class Bounds extends h2d.col.Collider {
	/**
		 X-axis left-most bounding box point. 
	**/
	var xMin : Float;
	/**
		 Y-axis top-most bounding box point. 
	**/
	var yMin : Float;
	/**
		 X-axis right-most bounding box point. 
	**/
	var xMax : Float;
	/**
		 Y-axis bottom-most bounding box point. 
	**/
	var yMax : Float;
	/**
		
				X-axis position of the bounding box top-left corner. Modifying it alters both `Bounds.xMin` and `Bounds.xMax`.
			
	**/
	var x(get, set) : Float;
	/**
		
				Y-axis position of the bounding box top-left corner. Modifying it alters both `Bounds.yMin` and `Bounds.yMax`.
			
	**/
	var y(get, set) : Float;
	/**
		
				Width of the bounding box. Equivalent of `xMax - xMin`.
			
	**/
	var width(get, set) : Float;
	/**
		
				Height of the bounding box. Equivalent of `yMax - yMin`.
			
	**/
	var height(get, set) : Float;
	function rayIntersection(r:h2d.col.Ray):Float;
	/**
		
				Returns a new Bounds instance containing intersection results of this Bounds and the given Bounds `b`.
			
	**/
	function intersection(b:h2d.col.Bounds):h2d.col.Bounds;
	/**
		
				Returns a new Bounds instance containing union of this Bounds and the given Bounds `b`.
			
	**/
	function union(b:h2d.col.Bounds):h2d.col.Bounds;
	/**
		
				Copies the min/max values from the given Bounds `b` to this Bounds.
			
	**/
	function load(b:h2d.col.Bounds):Void;
	/**
		
				Scales the min/max values relative the current bounding box center point.
			
	**/
	function scaleCenter(v:Float):Void;
	/**
		
				Rotates the bounding box around `0,0` point by given `angle` and sets min/max to the new rotated boundaries.
			
	**/
	function rotate(angle:Float):Void;
	@:dox(hide)
	function toString():String;
}