package h3d.scene.pbr;

@:native("h3d.scene.pbr.PointLight") extern class PointLight extends h3d.scene.pbr.Light {
	function new(?parent:h3d.scene.Object):Void;
	var size : Float;
	var zNear : Float;
	/**
		
				Alias for uniform scale.
			
	**/
	var range(get, set) : Float;
	override function clone(?o:h3d.scene.Object):h3d.scene.Object;
	private function get_range():Float;
	private function set_range(v:Float):Float;
}