package hxd.fmt.hmd;

@:native("hxd.fmt.hmd.Library") extern class GeometryBuffer {
	function new():Void;
	var vertexes : haxe.ds.Vector<hxd.impl.Float32>;
	var indexes : haxe.ds.Vector<Int>;
}

@:native("hxd.fmt.hmd.Library") extern class Library {
	function new(res:hxd.res.Resource, header:hxd.fmt.hmd.Data):Void;
	var resource(default, null) : hxd.res.Resource;
	var header(default, null) : hxd.fmt.hmd.Data;
	function getData():haxe.io.Bytes;
	function getDefaultFormat(stride:Int):{ var defs : Array<h3d.Vector>; var format : hxd.BufferFormat; };
	function load(format:hxd.BufferFormat, ?defaults:Array<h3d.Vector4>, ?modelIndex:Int):{ var index : hxd.IndexBuffer; var vertex : hxd.FloatBuffer; };
	@:noDebug
	function getBuffers(geom:hxd.fmt.hmd.Data.Geometry, format:hxd.BufferFormat, ?defaults:Array<h3d.Vector4>, ?material:Int):hxd.fmt.hmd.Library.GeometryBuffer;
	function dispose():Void;
	function getModelProperty<T>(objName:String, p:hxd.fmt.hmd.Data.Property<T>, ?def:T):T;
	function getLODInfos(model:hxd.fmt.hmd.Data.Model):{ var lodLevel : Int; var modelName : String; };
	function findLODs(modelName:String, lod0:hxd.fmt.hmd.Data.Model):Array<hxd.fmt.hmd.Data.Model>;
	function patchLodsMaterials(lod0:hxd.fmt.hmd.Data.Model, lods:Array<hxd.fmt.hmd.Data.Model>):Void;
	function makeObject(?loadTexture:String -> h3d.mat.Texture):h3d.scene.Object;
	function loadAnimation(?name:String):h3d.anim.Animation;
	@:allow(h3d.anim.Skin)
	function loadSkin(geom:hxd.fmt.hmd.Data.Geometry, skin:h3d.anim.Skin, ?optimize:Bool):Void;
}