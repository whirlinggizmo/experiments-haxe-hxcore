package h2d.col;

/**
 An `hxd.Pixels`-based collider. Checks for pixel color value under point to be above the cutoff value.
 
 Note that it checks as `channel > cutoff`, not `channel >= cutoff`, hence cutoff value of 255 would never pass the test.
 */
/**
	
		An `hxd.Pixels`-based collider. Checks for pixel color value under point to be above the cutoff value.
	
		Note that it checks as `channel > cutoff`, not `channel >= cutoff`, hence cutoff value of 255 would never pass the test.
	
**/
@:native("h2d.col.PixelsCollider") extern class PixelsCollider extends h2d.col.Collider {
	/**
		
				Create new BitmapCollider with specified bitmap, channel cutoff values and check mode.
				@param pixels The source pixel data which is tested against.
				@param alphaCutoff The alpha channel cutoff value.
				@param redCutoff The red channel cutoff value.
				@param greenCutoff The green channel cutoff value.
				@param blueCutoff The blue channel cutoff value.
				@param collideOnAny Whether to pass the collision check if any channel is above the threshold or if all channels should pass the test.
			
	**/
	function new(pixels:hxd.Pixels, ?alphaCutoff:Int, ?redCutoff:Int, ?greenCutoff:Int, ?blueCutoff:Int, ?collideOnAny:Bool):Void;
	/**
		
				The source pixel data which is tested against.
			
	**/
	var pixels : hxd.Pixels;
	/**
		
				The red channel cutoff value in range of -1...255
		
				Set to 255 to always fail the test.
				@default 255
			
	**/
	var redCutoff : Int;
	/**
		
				The green channel cutoff value in range of -1...255
		
				Set to 255 to always fail the test.
				@default 255
			
	**/
	var greenCutoff : Int;
	/**
		
				The blue channel cutoff value in range of -1...255
		
				Set to 255 to always fail the test.
				@default 255
			
	**/
	var blueCutoff : Int;
	/**
		
				The alpha channel cutoff value in range of -1...255
		
				Set to 255 to always fail the test.
				@default 127
			
	**/
	var alphaCutoff : Int;
	/**
		
				If true, will collide if any channel is above cutoff. Otherwise will collide only if all channels above their cutoff values.
				@default true
			
	**/
	var collideOnAny : Bool;
	/**
		
				Horizontal stretch of pixels to check for collision.
			
	**/
	var scaleX : Float;
	/**
		
				Vertical stretch of pixels to check for collision.
			
	**/
	var scaleY : Float;
	/**
		
				Checks if the pixel under given Point `p` passes the threshold test.
			
	**/
	override function contains(p:h2d.col.Point):Bool;
	override function collideCircle(c:h2d.col.Circle):Bool;
	override function collideBounds(b:h2d.col.Bounds):Bool;
}