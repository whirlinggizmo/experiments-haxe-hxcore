package h3d.scene.pbr;

@:native("h3d.scene.pbr.LightBuffer") extern class LightBuffer {
	function new():Void;
	var defaultForwardShader : h3d.shader.pbr.DefaultForward;
	function setBuffers(s:h3d.shader.pbr.DefaultForward):Void;
	function sortLights(ctx:h3d.scene.RenderContext):Array<h3d.scene.pbr.Light>;
	function fillLights(lights:Array<h3d.scene.pbr.Light>, shadows:Bool):Void;
	function sync(ctx:h3d.scene.RenderContext):Void;
	function dispose():Void;
}