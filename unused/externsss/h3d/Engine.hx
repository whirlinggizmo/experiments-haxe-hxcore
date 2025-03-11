package h3d;

@:native("h3d.Engine") extern enum DepthBinding {
	ReadWrite;
	ReadOnly;
	DepthOnly;
	NotBound;
}

@:native("h3d.Engine") extern class Engine {
	var driver(default, null) : h3d.impl.Driver;
	var mem(default, null) : h3d.impl.MemoryManager;
	var hardware(default, null) : Bool;
	var width(default, null) : Int;
	var height(default, null) : Int;
	var debug(default, set) : Bool;
	var drawTriangles(default, null) : Int;
	var drawCalls(default, null) : Int;
	var dispatches(default, null) : Int;
	var shaderSwitches(default, null) : Int;
	var backgroundColor : Int;
	var autoResize : Bool;
	var fullScreen(default, set) : Bool;
	var fps(get, never) : Float;
	var ready(default, null) : Bool;
	function setDriver(d:h3d.impl.Driver):Void;
	function init():Void;
	function driverName(?details:Bool):String;
	function selectShader(shader:hxsl.RuntimeShader):Void;
	function selectMaterial(pass:h3d.mat.Pass):Void;
	function uploadShaderBuffers(buffers:h3d.shader.Buffers, which:h3d.shader.Buffers.BufferKind):Void;
	function renderIndexed(b:h3d.Buffer, indexes:h3d.Indexes, ?startTri:Int, ?drawTri:Int):Void;
	function renderMultiBuffers(format:hxd.BufferFormat.MultiFormat, buffers:Array<h3d.Buffer>, indexes:h3d.Indexes, ?startTri:Int, ?drawTri:Int):Void;
	function renderInstanced(indexes:h3d.Indexes, commands:h3d.impl.InstanceBuffer):Void;
	private function set_debug(d:Bool):Bool;
	function onContextLost():Void;
	function onReady():Void;
	private function set_fullScreen(v:Bool):Bool;
	function onResized():Void;
	function resize(width:Int, height:Int):Void;
	function begin():Bool;
	function hasFeature(f:h3d.impl.Driver.Feature):Bool;
	function end():Void;
	function getCurrentTarget():h3d.mat.Texture;
	function pushTarget(tex:h3d.mat.Texture, ?layer:Int, ?mipLevel:Int, ?depthBinding:h3d.Engine.DepthBinding):Void;
	function pushTargets(textures:Array<h3d.mat.Texture>, ?depthBinding:h3d.Engine.DepthBinding):Void;
	function pushDepth(depthBuffer:h3d.mat.Texture):Void;
	function popTarget():Void;
	function clearF(color:h3d.Vector4, ?depth:Float, ?stencil:Int):Void;
	function clear(?color:Int, ?depth:Float, ?stencil:Int):Void;
	/**
		
			 * Sets up a scissored zone to eliminate pixels outside the given range.
			 * Call with no parameters to reset to full viewport.
			 
	**/
	function setRenderZone(?x:Int, ?y:Int, ?width:Int, ?height:Int):Void;
	function render(obj:{ function render(engine:h3d.Engine):Void; }):Bool;
	function onTextureBiasChanged(t:h3d.mat.Texture):Void;
	function dispose():Void;
	private function get_fps():Float;
	static var SOFTWARE_DRIVER : Bool;
	static var ANTIALIASING : Int;
}