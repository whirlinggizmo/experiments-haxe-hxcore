package hxcore.util;

class MathUtils {
	public static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.min(Math.max(value, min), max);
	}

	public static function lerp(a:Float, b:Float, t:Float):Float {
		return a + (b - a) * t;
	}

	// Linearly interpolate angle (in radians)
	public static function lerpAngle(a:Float, b:Float, t:Float):Float {
		var diff = b - a;
		if (diff > Math.PI) {
			diff -= 2.0 * Math.PI;
		} else if (diff < -Math.PI) {
			diff += 2.0 * Math.PI;
		}
		return a + diff * t;
	}

	public static function smoothstep(edge0:Float, edge1:Float, x:Float):Float {
		var t = MathUtils.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
		return t * t * (3.0 - 2.0 * t);
	}

	public static function round(number:Float, ?precision = 2):Float {
		number *= Math.pow(10, precision);
		return Math.round(number) / Math.pow(10, precision);
	}   
}
