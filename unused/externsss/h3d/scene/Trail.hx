package h3d.scene;

@:native("h3d.scene.Trail") extern class Trail extends h3d.scene.Mesh {
	function new(?parent:h3d.scene.Object):Void;
	var duration : Float;
	var angle : Float;
	var sizeStart : Float;
	var sizeEnd : Float;
	var movementMin : Float;
	var movementMax : Float;
	var smoothness : Float;
	var materialData : { };
	var texture(get, set) : h3d.mat.Texture;
	private function get_texture():h3d.mat.Texture;
	private function set_texture(t:h3d.mat.Texture):h3d.mat.Texture;
	function getMaterialProps():Any;
	function clear():Void;
	function save():Dynamic;
	function load(obj:Dynamic):Void;
}