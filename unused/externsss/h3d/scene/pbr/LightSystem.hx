package h3d.scene.pbr;

@:access(h3d.scene.pbr.Light) @:native("h3d.scene.pbr.LightSystem") extern class LightSystem extends h3d.scene.LightSystem {
	function new():Void;
	var lightBuffer : h3d.scene.pbr.LightBuffer;
	var forwardMode : Bool;
	var lightingShaders : Array<hxsl.Shader>;
	override function computeLight(obj:h3d.scene.Object, shaders:hxsl.ShaderList):hxsl.ShaderList;
	function drawShadows(light:h3d.scene.pbr.Light, passes:h3d.pass.PassList):Void;
	function drawScreenLights(r:h3d.scene.Renderer, lightPass:h3d.pass.ScreenFx<Dynamic>, ?shadows:Bool):Void;
	override function dispose():Void;
}