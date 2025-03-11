package h3d.prim;

@:native("h3d.prim.HMDModel") extern class HMDModel extends h3d.prim.MeshPrimitive {
	function new(data:hxd.fmt.hmd.Data.Geometry, dataPos:Int, lib:hxd.fmt.hmd.Library, ?lods:Array<hxd.fmt.hmd.Data.Model>):Void;
	override function hasInput(name:String):Bool;
	override function triCount():Int;
	override function vertexCount():Int;
	override function getBounds():h3d.col.Bounds;
	override function selectMaterial(material:Int, lod:Int):Void;
	override function getMaterialIndexStart(material:Int, ?lod:Int):Int;
	override function getMaterialIndexCount(material:Int, ?lod:Int):Int;
	function getDataBuffers(fmt:hxd.BufferFormat, ?defaults:Array<h3d.Vector4>, ?material:Int):hxd.fmt.hmd.Library.GeometryBuffer;
	function loadSkin(skin:h3d.anim.Skin):Void;
	override function alloc(engine:h3d.Engine):Void;
	function recomputeNormals(?name:String):Void;
	function addTangents():Void;
	override function render(engine:h3d.Engine):Void;
	override function getCollider():h3d.col.Collider;
	override function lodCount():Int;
	override function screenRatioToLod(screenRatio:Float):Int;
	function getLodConfig():Array<Float>;
	static var lodExportKeyword : String;
}