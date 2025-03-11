package h3d.prim;

@:native("h3d.prim.Sphere") extern class Sphere extends h3d.prim.Polygon {
	function new(?ray:Float, ?segsW:Int, ?segsH:Int, ?portion:Float):Void;
	override function getCollider():h3d.col.Collider;
	override function addNormals():Void;
	override function addUVs():Void;
	static function defaultUnitSphere():h3d.prim.Sphere;
}