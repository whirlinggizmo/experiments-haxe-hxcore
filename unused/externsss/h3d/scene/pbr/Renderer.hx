package h3d.scene.pbr;

@:enum typedef DisplayMode = String;

@:enum typedef SkyMode = String;

@:enum typedef TonemapMap = String;

typedef RenderProps = {
	@:optional
	var a : Float;
	@:optional
	var b : Float;
	@:optional
	var c : Float;
	@:optional
	var d : Float;
	@:optional
	var e : Float;
	var emissive : Float;
	var exposure : Float;
	@:optional
	var forceDirectDiscard : Bool;
	var mode : h3d.scene.pbr.Renderer.DisplayMode;
	var occlusion : Float;
	var sky : h3d.scene.pbr.Renderer.SkyMode;
	@:optional
	var skyColor : Int;
	var tone : h3d.scene.pbr.Renderer.TonemapMap;
};

@:src({
		@ignore @param var depthTexture:Channel;
		function fragment() {
			pixelColor = vec4(depthTexture.get(calculatedUV));
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.pbr.Renderer") extern class DepthCopy extends h3d.shader.ScreenShader {
	function new():Void;
	var depthTexture(get, set) : hxsl.Types.TextureChannel;
	var depthTextureChannel(get, set) : hxsl.Channel;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function clone():hxsl.Shader;
}

@:native("h3d.scene.pbr.Renderer") extern class Renderer extends h3d.scene.Renderer {
	function new(?env:h3d.scene.pbr.Environment):Void;
	var cullingDistanceFactor : Float;
	var skyMode : h3d.scene.pbr.Renderer.SkyMode;
	var toneMode : h3d.scene.pbr.Renderer.TonemapMap;
	var displayMode : h3d.scene.pbr.Renderer.DisplayMode;
	var env : h3d.scene.pbr.Environment;
	var exposure(get, set) : Float;
	override function addShader(s:hxsl.Shader):Void;
	override function getPassByName(name:String):h3d.pass.Output;
	override function start():Void;
	function getPbrDepth():h3d.mat.Texture;
	override function getDefaultProps(?kind:String):Any;
	override function refreshProps():Void;
	static var LIGHTMAP_STENCIL(default, never) : Int;
}