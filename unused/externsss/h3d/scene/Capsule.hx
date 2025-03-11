package h3d.scene;

@:native("h3d.scene.Capsule") extern class Capsule extends h3d.scene.Graphics {
	function new(?color:Int, ?radius:Float, ?length:Float, ?depth:Bool, ?parent:h3d.scene.Object):Void;
	var color : Int;
	var radius(default, set) : Float;
	var length(default, set) : Float;
	private function set_radius(v:Float):Float;
	private function set_length(v:Float):Float;
	override function getLocalCollider():h3d.col.Collider;
}