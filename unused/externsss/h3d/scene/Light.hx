package h3d.scene;

@:native("h3d.scene.Light") extern class Light extends h3d.scene.Object {
	@:noCompletion
	var next : h3d.scene.Light;
	var color(get, set) : h3d.Vector;
	private function get_color():h3d.Vector;
	private function set_color(v:h3d.Vector):h3d.Vector;
}