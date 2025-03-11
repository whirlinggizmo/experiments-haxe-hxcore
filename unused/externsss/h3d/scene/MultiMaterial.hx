package h3d.scene;

@:native("h3d.scene.MultiMaterial") extern class MultiMaterial extends h3d.scene.Mesh {
	function new(prim:h3d.prim.Primitive, ?mats:Array<h3d.mat.Material>, ?parent:h3d.scene.Object):Void;
	var materials : Array<h3d.mat.Material>;
	override function getMeshMaterials():Array<h3d.mat.Material>;
	override function clone(?o:h3d.scene.Object):h3d.scene.MultiMaterial;
	override function getMaterialByName(name:String):h3d.mat.Material;
	override function getMaterials(?a:Array<h3d.mat.Material>, ?recursive:Bool):Array<h3d.mat.Material>;
}