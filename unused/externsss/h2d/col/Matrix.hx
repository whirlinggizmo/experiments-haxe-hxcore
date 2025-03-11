package h2d.col;

/**
 An affine 2D 2x3 matrix.
 
 Matrix properties are as follows:
 ```
 [a, c, x]
 [b, d, y]
 ```
 */
/**
	
		An affine 2D 2x3 matrix.
	
		Matrix properties are as follows:
		```
		[a, c, x]
		[b, d, y]
		```
	
**/
@:native("h2d.col.Matrix") extern class Matrix {
	var a : Float;
	var b : Float;
	var c : Float;
	var d : Float;
	var x : Float;
	var y : Float;
	/**
		
				Inverts the matrix to perform the opposite transformation. Can be used to undo the previously applied transformation.
				@see `Matrix.inverse`
			
	**/
	function invert():Void;
	/**
		
				Sets this Matrix value to be the inverse of the given Matrix `m`.
			
	**/
	function inverse(m:h2d.col.Matrix):Void;
	/**
		
				Concatenates Matrix `a` and `b` and stores the result in this Matrix.
				Matrix can be the target of of it's own `multiply`.
				Keep in mind that order of matrixes matter in concatenation.
			
	**/
	function multiply(a:h2d.col.Matrix, b:h2d.col.Matrix):Void;
	/**
		
				Applies rotation transform to the Matrix by given `angle`.
			
	**/
	function rotate(angle:Float):Void;
	/**
		
				Applies skewing transform to the Matrix by given `sx` and `sy`.
			
	**/
	function skew(sx:Float, sy:Float):Void;
	/**
		
				Applies skewing transform on X-axis to the Matrix by given `sx`.
			
	**/
	function skewX(sx:Float):Void;
	/**
		
				Applies skewing transform on Y-axis to the Matrix by given `sy`.
			
	**/
	function skewY(sy:Float):Void;
	/**
		
				Returns a copy of this Matrix.
			
	**/
	function clone():h2d.col.Matrix;
	@:dox(hide)
	function toString():String;
}