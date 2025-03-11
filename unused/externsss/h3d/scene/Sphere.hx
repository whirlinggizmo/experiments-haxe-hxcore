package h3d.scene;

@:native("h3d.scene.Sphere") extern class Sphere extends h3d.scene.Graphics {
	function new(?color:Int, ?radius:Float, ?depth:Bool, ?parent:h3d.scene.Object):Void;
	var color : Int;
	var radius(default, set) : Float;
	private function set_radius(v:Float):Float;
	override function getLocalCollider():h3d.col.Collider;
}