package h2d.col;

/**
 See `Polynomial.regress`.
 */
/**
	
		See `Polynomial.regress`.
	
**/
@:native("h2d.col.Polynomial") extern class Polynomial {
	/**
		
				Calculate the best fit curve of given degree that match the input values. Returns the polynomial exponents. For instance [2,8,-5] will represent 2 + 8 x - 5 x^2
			
	**/
	static function regress(xVals:Array<Float>, yVals:Array<Float>, degree:Int):Array<Float>;
}