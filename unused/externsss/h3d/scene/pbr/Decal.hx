package h3d.scene.pbr;

@:native("h3d.scene.pbr.Decal") extern class Decal extends h3d.scene.Mesh {
	function new(primitive:h3d.prim.Primitive, ?material:h3d.mat.Material, ?parent:h3d.scene.Object):Void;
}