package h3d.prim;

@:native("h3d.prim.RawPrimitive") extern class RawPrimitive extends h3d.prim.Primitive {
	function new(inf:{ @:optional
	var bounds : h3d.col.Bounds; var format : hxd.BufferFormat; @:optional
	var ibuf : hxd.IndexBuffer; var vbuf : hxd.FloatBuffer; }, ?persist:Bool):Void;
	var onContextLost : () -> { public var vbuf(default, default) : hxd.FloatBuffer; @:optional
	public var ibuf(default, default) : hxd.IndexBuffer; public var format(default, default) : hxd.BufferFormat; };
	override function alloc(engine:h3d.Engine):Void;
	override function getBounds():h3d.col.Bounds;
	override function triCount():Int;
	override function vertexCount():Int;
}