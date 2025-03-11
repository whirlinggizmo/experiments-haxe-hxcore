package h3d.prim;

@:native("h3d.prim.MeshPrimitive") extern class MeshPrimitive extends h3d.prim.Primitive {
	function hasInput(name:String):Bool;
	function resolveBuffer(name:String):h3d.Buffer;
	function removeBuffer(buf:h3d.Buffer):Void;
	function addBuffer(buf:h3d.Buffer):Void;
	override function dispose():Void;
	override function render(engine:h3d.Engine):Void;
}