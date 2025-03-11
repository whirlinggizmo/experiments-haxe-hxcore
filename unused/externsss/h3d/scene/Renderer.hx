package h3d.scene;

@:native("h3d.scene.Renderer") extern class PassObjects {
	function new():Void;
	var name : String;
	var passes : Dynamic;
	var rendered : Bool;
}

@:native("h3d.scene.Renderer") extern enum RenderMode {
	Default;
	LightProbe;
}

 @:native("h3d.scene.Renderer") extern class Renderer  {
	function new():Void;
	var effects : Array<Dynamic>;
	var renderMode : h3d.scene.Renderer.RenderMode;
	var shadows : Bool;
	function getEffect<T:(h3d.impl.RendererFX)>(cl:Class<T>):T;
	function dispose():Void;
	/**
		
				Inject a post process shader for the current frame. Shaders are reset after each render.
			
	**/
	function addShader(s:hxsl.Shader):Void;
	function getPass<T:(Dynamic)>(c:Class<T>):T;
	function getPassByName(name:String):Dynamic;
	function start():Void;
	function startEffects():Void;
	function process(passes:Array<h3d.scene.Renderer.PassObjects>):Void;
	function computeDispatch(shader:hxsl.Shader, ?x:Int, ?y:Int, ?z:Int):Void;
}