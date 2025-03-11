package h3d.scene.pbr;

@:native("h3d.scene.pbr.SpotLight") extern class SpotLight extends h3d.scene.pbr.Light {
	function new(?parent:h3d.scene.Object):Void;
	var range(get, set) : Float;
	var angle(default, set) : Float;
	var fallOff : Float;
	var cookie : h3d.mat.Texture;
	override function clone(?o:h3d.scene.Object):h3d.scene.Object;
	private function get_range():Float;
	private function set_range(v:Float):Float;
	private function set_angle(v:Float):Float;
	static function spotLightPrim():h3d.prim.Polygon;
}