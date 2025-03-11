package h3d.scene.fwd;

@:native("h3d.scene.fwd.Renderer") extern class DepthPass extends h3d.pass.Output {
	function new():Void;
	var enableSky : Bool;
	override function draw(passes:h3d.pass.PassList, ?sort:h3d.pass.PassList -> Void):Void;
}

@:native("h3d.scene.fwd.Renderer") extern class NormalPass extends h3d.pass.Output {
	function new():Void;
	override function draw(passes:h3d.pass.PassList, ?sort:h3d.pass.PassList -> Void):Void;
}

@:native("h3d.scene.fwd.Renderer") extern class Renderer extends h3d.scene.Renderer {
	function new():Void;
	var depth : h3d.pass.Output;
	var normal : h3d.pass.Output;
	var shadow : h3d.pass.DefaultShadowMap;
	override function getPassByName(name:String):h3d.pass.Output;
}