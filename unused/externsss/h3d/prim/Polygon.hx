package h3d.prim;

@:native("h3d.prim.Polygon") extern class Polygon extends h3d.prim.MeshPrimitive {
	function new(points:Array<h3d.col.Point>, ?idx:hxd.IndexBuffer):Void;
	var points : Array<h3d.col.Point>;
	var normals : Array<h3d.col.Point>;
	var tangents : Array<h3d.col.Point>;
	var uvs : Array<h3d.prim.UV>;
	var idx : hxd.IndexBuffer;
	var colors : Array<h3d.col.Point>;
	override function getBounds():h3d.col.Bounds;
	override function alloc(engine:h3d.Engine):Void;
	function unindex():Void;
	function translate(dx:Float, dy:Float, dz:Float):Void;
	function scale(s:Float):Void;
	function addNormals():Void;
	function addTangents():Void;
	function addUVs():Void;
	function uvScale(su:Float, sv:Float):Void;
	override function triCount():Int;
	override function vertexCount():Int;
	override function getCollider():h3d.col.Collider;
	override function render(engine:h3d.Engine):Void;
}