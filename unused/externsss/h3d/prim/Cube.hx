package h3d.prim;

@:native("h3d.prim.Cube") extern class Cube extends h3d.prim.Polygon {
	function new(?x:Float, ?y:Float, ?z:Float, ?centered:Bool):Void;
	override function addUVs():Void;
	function addUniformUVs(?scale:Float):Void;
	override function getCollider():h3d.col.Collider;
	static function defaultUnitCube():h3d.prim.Cube;
}