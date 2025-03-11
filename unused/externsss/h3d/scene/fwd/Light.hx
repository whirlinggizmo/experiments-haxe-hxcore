package h3d.scene.fwd;

@:native("h3d.scene.fwd.Light") extern class Light extends h3d.scene.Light {
	function new(shader:hxsl.Shader, ?parent:h3d.scene.Object):Void;
	var priority : Int;
	var enableSpecular(get, set) : Bool;
	private function get_enableSpecular():Bool;
	private function set_enableSpecular(b:Bool):Bool;
}