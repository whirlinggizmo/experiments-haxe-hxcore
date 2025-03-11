package h3d.prim;

@:native("h3d.prim.Cylinder") extern class Cylinder extends h3d.prim.Quads {
	function new(segs:Int, ?ray:Float, ?height:Float, ?centered:Bool):Void;
	override function addUVs():Void;
	/**
		
			 * Get a default unit Cylinder with 
			 * segs = 16, ray = 0.5, height = 1.0, centered = false
			 * and add UVs to it. If it has not be cached, it is cached and subsequent
			 * calls to this method will return Cylinder from cache.
			 * @param segs Optional number of segments of the cylinder, default 16
			 
	**/
	static function defaultUnitCylinder(?segs:Int):h3d.prim.Cylinder;
}