package h3d.scene.fwd;

@:native("h3d.scene.fwd.PointLight") extern class PointLight extends h3d.scene.fwd.Light {
	function new(?parent:h3d.scene.Object):Void;
	var params(get, set) : h3d.Vector;
}