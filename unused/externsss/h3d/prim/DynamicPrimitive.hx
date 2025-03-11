package h3d.prim;

@:native("h3d.prim.DynamicPrimitive") extern class DynamicPrimitive extends h3d.prim.Primitive {
	function new(format:hxd.BufferFormat):Void;
	/**
		 Minimum number of elements in vertex buffer 
	**/
	var minVSize : Int;
	/**
		 Minimum number of elements in index index buffer 
	**/
	var minISize : Int;
	var bounds : h3d.col.Bounds;
	override function getBounds():h3d.col.Bounds;
	function getBuffer(vertices:Int):hxd.FloatBuffer;
	function getIndexes(count:Int):hxd.IndexBuffer;
	function flush():Void;
	override function dispose():Void;
	override function triCount():Int;
	override function render(engine:h3d.Engine):Void;
}