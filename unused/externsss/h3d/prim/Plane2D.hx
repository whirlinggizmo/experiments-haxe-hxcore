package h3d.prim;

@:native("h3d.prim.Plane2D") extern class Plane2D extends h3d.prim.Primitive {
	function new():Void;
	override function triCount():Int;
	override function vertexCount():Int;
	override function alloc(engine:h3d.Engine):Void;
	override function render(engine:h3d.Engine):Void;
	static function get():Dynamic;
}