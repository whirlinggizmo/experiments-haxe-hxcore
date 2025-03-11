package h3d.scene.fwd;

@:native("h3d.scene.fwd.LightSystem") extern class LightSystem extends h3d.scene.LightSystem {
	function new():Void;
	var maxLightsPerObject : Int;
	var perPixelLighting : Bool;
	var ambientLight(default, null) : h3d.Vector;
	/**
		
				In the additive lighting model (by default), the lights are added after the ambient.
				In the new non additive ligthning model, the lights will be modulated against the ambient, so an ambient of 1 will reduce lights intensities to 0.
			
	**/
	var additiveLighting(get, set) : Bool;
	private function get_additiveLighting():Bool;
	private function set_additiveLighting(b:Bool):Bool;
	override function initLights(ctx:h3d.scene.RenderContext):Void;
	override function initGlobals(globals:hxsl.Globals):Void;
	override function computeLight(obj:h3d.scene.Object, shaders:hxsl.ShaderList):hxsl.ShaderList;
}