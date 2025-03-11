package h3d.prim;

@:native("h3d.prim.Disc") extern class Disc extends h3d.prim.Polygon {
	function new(?radius:Float, ?segments:Int, ?thetaStart:Float, ?thetaLength:Float):Void;
	var radius(default, null) : Float;
	var segments(default, null) : Int;
	override function addUVs():Void;
	/**
		
			 * Get a default unit Disc with 
			 * radius = 0.5, segments = 8, thetaStart = 0.0, thetaLength = Math.PI * 2
			 * and add UVs to it. If it has not be cached, it is cached and subsequent
			 * calls to this method will return Disc from cache.
			 
	**/
	static function defaultUnitDisc():h3d.prim.Disc;
}