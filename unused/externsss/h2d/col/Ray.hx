package h2d.col;

/**
 A raycast from the given position in a specified direction.
 */
/**
	
		A raycast from the given position in a specified direction.
	
**/
@:native("h2d.col.Ray") extern class Ray {
	/**
		 X position of the ray start. 
	**/
	var px : Float;
	/**
		 Y position of the ray start. 
	**/
	var py : Float;
	/**
		 X normal of the ray direction. 
	**/
	var lx : Float;
	/**
		 Y normal of the ray direction. 
	**/
	var ly : Float;
}