package h3d.scene;

@:native("h3d.scene.World") extern class WorldElement {
	function new(model:h3d.scene.World.WorldModel, mat:h3d.Matrix, optimized:Bool):Void;
	var model : h3d.scene.World.WorldModel;
	var transform : h3d.Matrix;
	var optimized : Bool;
}

@:native("h3d.scene.World") extern class WorldChunk {
	function new(cx:Int, cy:Int):Void;
	var cx : Int;
	var cy : Int;
	var x : Float;
	var y : Float;
	var root : h3d.scene.Object;
	var buffers : Map<Int, h3d.scene.Mesh>;
	var bounds : h3d.col.Bounds;
	var initialized : Bool;
	var lastFrame : Int;
	var elements : Array<h3d.scene.World.WorldElement>;
	function dispose():Void;
}

@:native("h3d.scene.World") extern class WorldMaterial {
	function new():Void;
	var bits : Int;
	var t : h3d.mat.BigTexture.BigTextureElement;
	var spec : h3d.mat.BigTexture.BigTextureElement;
	var normal : h3d.mat.BigTexture.BigTextureElement;
	var mat : hxd.fmt.hmd.Data.Material;
	var culling : Bool;
	var blend : h3d.mat.BlendMode;
	var killAlpha : Float;
	var emissive : Float;
	var stencil : Int;
	var lights : Bool;
	var shadows : Bool;
	var shaders : Array<hxsl.Shader>;
	var name : String;
	function clone():h3d.scene.World.WorldMaterial;
	function updateBits():Void;
}

@:native("h3d.scene.World") extern class WorldModelGeometry {
	function new(m:h3d.scene.World.WorldMaterial):Void;
	var m : h3d.scene.World.WorldMaterial;
	var startVertex : Int;
	var startIndex : Int;
	var vertexCount : Int;
	var indexCount : Int;
}

@:native("h3d.scene.World") extern enum OptAlgorithm {
	None;
	/**
		
				Sort triangles by Z descending
			
	**/
	TopDown;
}

@:native("h3d.scene.World") extern class WorldModel {
	function new(r:hxd.res.Model):Void;
	var r : hxd.res.Model;
	var format : hxd.BufferFormat;
	var buf : hxd.FloatBuffer;
	var idx : hxd.IndexBuffer;
	var geometries : Array<h3d.scene.World.WorldModelGeometry>;
	var bounds : h3d.col.Bounds;
	function optimize(algo:h3d.scene.World.OptAlgorithm):Void;
}

@:native("h3d.scene.World") extern class World extends h3d.scene.Object {
	function new(chunkSize:Int, parent:h3d.scene.Object, ?autoCollect:Bool):Void;
	var chunkSize(default, null) : Int;
	var enableSpecular : Bool;
	var enableNormalMaps : Bool;
	var specularInAlpha : Bool;
	var wrap(default, set) : h3d.mat.Data.Wrap;
	function set_wrap(v:h3d.mat.Data.Wrap):h3d.mat.Data.Wrap;
	function garbage():Void;
	function done():Void;
	@:noDebug
	function loadModel(r:hxd.res.Model, ?filter:hxd.fmt.hmd.Data.Model -> Bool):h3d.scene.World.WorldModel;
	/**
		
				Dispose the World instance.
				Note: Only chunked world objects will be disposed. Any objects added to World object will be disposed when World is removed from scene or scene is disposed.
			
	**/
	function dispose():Void;
	function onContextLost():Void;
	function add(model:h3d.scene.World.WorldModel, x:Float, y:Float, z:Float, ?scale:Float, ?rotation:Float):Void;
	function addTransform(model:h3d.scene.World.WorldModel, mat:h3d.Matrix):Void;
	function getWorldBounds(?b:h3d.col.Bounds):h3d.col.Bounds;
}