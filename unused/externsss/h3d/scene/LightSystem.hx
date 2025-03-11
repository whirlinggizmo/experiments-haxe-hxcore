package h3d.scene;

@:native("h3d.scene.LightSystem") extern class LightSystem {
	function new():Void;
	var drawPasses : Int;
	var shadowLight : h3d.scene.Light;
	function initGlobals(globals:Dynamic):Void;
	function initLights(ctx:Dynamic):Void;
	function computeLight(obj:h3d.scene.Object, shaders:Dynamic):Dynamic;
	function dispose():Void;
}