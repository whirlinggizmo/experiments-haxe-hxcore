package h3d.scene.pbr;

@:native("h3d.scene.pbr.DirLight") extern class DirLight extends h3d.scene.pbr.Light {
	function new(?dir:h3d.Vector, ?parent:h3d.scene.Object, ?cascade:Bool):Void;
	override function clone(?o:h3d.scene.Object):h3d.scene.Object;
}