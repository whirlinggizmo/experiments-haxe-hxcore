package h3d.prim;

@:native("h3d.prim.Instanced") extern class Instanced extends h3d.prim.Primitive {
	function new():Void;
	var commands : h3d.impl.InstanceBuffer;
	var bounds : h3d.col.Bounds;
	function setMesh(m:h3d.prim.MeshPrimitive):Void;
	function initBounds():Void;
	override function dispose():Void;
	override function incref():Void;
	override function decref():Void;
	override function getBounds():h3d.col.Bounds;
	override function screenRatioToLod(screenRatio:Float):Int;
	function setCommand(material:Int, lod:Int, count:Int):Void;
	override function render(engine:h3d.Engine):Void;
}