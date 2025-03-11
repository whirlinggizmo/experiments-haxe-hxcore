package h3d.scene.fwd;

@:native("h3d.scene.fwd.DirLight") extern class DirLight extends h3d.scene.fwd.Light {
	function new(?dir:h3d.Vector, ?parent:h3d.scene.Object):Void;
}