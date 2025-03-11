package h2d.col;

/**
 An integer-based bounding box.
 @see `h2d.col.Bounds`
 */
/**
	
		An integer-based bounding box.
		@see `h2d.col.Bounds`
	
**/
@:native("h2d.col.IBounds") extern class IBounds {
	/**
		 X-axis left-most bounding box point. 
	**/
	var xMin : Int;
	/**
		 Y-axis top-most bounding box point. 
	**/
	var yMin : Int;
	/**
		 X-axis right-most bounds box point. 
	**/
	var xMax : Int;
	/**
		 Y-axis bottom-most bounding box point. 
	**/
	var yMax : Int;
	/**
		
				X-axis position of the bounding-box top-left corner. Modifying it alters both `xMin` and `xMax`.
			
	**/
	var x(get, set) : Int;
	/**
		
				Y-axis position of the bounding-box top-left corner. Modifying it alters both `xMin` and `xMax`.
			
	**/
	var y(get, set) : Int;
	/**
		
				Width of the bounding box. Equivalent of `xMax - xMin`.
			
	**/
	var width(get, set) : Int;
	/**
		
				Height of the bounding box. Equivalent of `yMax - yMin`.
			
	**/
	var height(get, set) : Int;
	/**
		
				Returns new Bounds instance containing intersection results of this IBounds and given IBounds `b`.
			
	**/
	function intersection(b:h2d.col.IBounds):h2d.col.IBounds;
	/**
		
				Returns new Bounds instance containing union of this IBounds and given IBounds `b`.
			
	**/
	function union(b:h2d.col.IBounds):h2d.col.IBounds;
	/**
		
				Copies min/max values from given IBounds `b` to this IBounds.
			
	**/
	function load(b:h2d.col.IBounds):Void;
	@:dox(hide)
	function toString():String;
}