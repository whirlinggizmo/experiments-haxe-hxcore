package h3d.prim;

@:native("h3d.prim.UV") extern class UV {
	function new(u:Float, v:Float):Void;
	var u : Float;
	var v : Float;
	function clone():h3d.prim.UV;
}