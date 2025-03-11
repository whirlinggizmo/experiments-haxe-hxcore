package h3d.scene;

@:native("h3d.scene.Box") extern class Box extends h3d.scene.Graphics {
	function new(?color:Int, ?bounds:h3d.col.Bounds, ?depth:Bool, ?parent:h3d.scene.Object):Void;
	var color : Int;
	var bounds : h3d.col.Bounds;
	var thickness : Float;
	override function clone(?o:h3d.scene.Object):h3d.scene.Object;
	override function getLocalCollider():h3d.col.Collider;
}