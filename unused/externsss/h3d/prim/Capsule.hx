package h3d.prim;

@:native("h3d.prim.Capsule") extern class Capsule extends h3d.prim.Polygon {
	function new(?ray:Float, ?length:Float, ?segs:Int):Void;
	override function getCollider():h3d.col.Collider;
	override function addNormals():Void;
	static function defaultUnitCapsule():h3d.prim.Capsule;
}