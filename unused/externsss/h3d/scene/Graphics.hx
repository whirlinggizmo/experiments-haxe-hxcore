package h3d.scene;

@:native("h3d.scene.Graphics") extern class Graphics extends h3d.scene.Mesh {
	function new(?parent:h3d.scene.Object):Void;
	/**
		
				Setting is3D to true will switch from a screen space line (constant size whatever the distance) to a world space line
			
	**/
	var is3D(default, set) : Bool;
	private function set_is3D(v:Bool):Bool;
	function clear():Void;
	function lineStyle(?size:Float, ?color:Int, ?alpha:Float):Void;
	function setColorF(r:Float, g:Float, b:Float, ?a:Float):Void;
	function setColor(color:Int, ?alpha:Float):Void;
	function moveTo(x:Float, y:Float, z:Float):Void;
	function lineTo(x:Float, y:Float, z:Float):Void;
}