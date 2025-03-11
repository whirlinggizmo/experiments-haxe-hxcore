package h3d.mat;

@:allow(h3d) @:native("h3d.mat.Texture") extern class Texture {
	function new(w:Int, h:Int, ?flags:Array<h3d.mat.Data.TextureFlags>, ?format:h3d.mat.Data.TextureFormat):Void;
	var id(default, null) : Int;
	var name(default, null) : String;
	var width(default, null) : Int;
	var height(default, null) : Int;
	var flags(default, null) : haxe.EnumFlags<h3d.mat.Data.TextureFlags>;
	var format(default, null) : h3d.mat.Data.TextureFormat;
	var mipMap(default, set) : h3d.mat.Data.MipMap;
	var filter(default, set) : h3d.mat.Data.Filter;
	var wrap(default, set) : h3d.mat.Data.Wrap;
	var layerCount(get, never) : Int;
	var startingMip : Int;
	var lodBias : Float;
	var mipLevels(get, never) : Int;
	var depthBias(default, set) : Float;
	var slopeScaledBias(default, set) : Float;
	var depthClamp : Bool;
	/**
		
				If this callback is set, the texture can be re-allocated when the 3D context has been lost or when
				it's been free because of lack of memory.
			
	**/
	var realloc : () -> Void;
	/**
		
				When the texture is used as render target, tells which depth buffer will be used.
				If set to null, depth testing is disabled.
			
	**/
	var depthBuffer : h3d.mat.Texture;
	private function get_mipLevels():Int;
	private function get_layerCount():Int;
	function alloc():Void;
	function isSRGB():Bool;
	function clone():h3d.mat.Texture;
	/**
		
				In case of out of GPU memory, textures that hasn't been used for a long time will be disposed.
				Calling this will make this texture not considered for auto disposal.
			
	**/
	function preventAutoDispose():Void;
	function preventForcedDispose():Void;
	/**
		
				Some textures might take some time to load. You can check flags.has(Loading)
				or add a waitLoad callback which will get called either immediately if the texture is already loaded
				or when loading is complete.
			
	**/
	function waitLoad(f:() -> Void):Void;
	function setName(n:String):Void;
	function set_depthBias(v:Float):Float;
	function set_slopeScaledBias(v:Float):Float;
	private function set_mipMap(m:h3d.mat.Data.MipMap):h3d.mat.Data.MipMap;
	private function set_filter(f:h3d.mat.Data.Filter):h3d.mat.Data.Filter;
	private function set_wrap(w:h3d.mat.Data.Wrap):h3d.mat.Data.Wrap;
	function resize(width:Int, height:Int):Void;
	function clearF(?r:Float, ?g:Float, ?b:Float, ?a:Float, ?layer:Int):Void;
	function clear(color:Int, ?alpha:Float, ?layer:Int):Void;
	function uploadBitmap(bmp:Dynamic, ?mipLevel:Int, ?layer:Int):Void;
	function uploadPixels(pixels:Dynamic, ?mipLevel:Int, ?layer:Int):Void;
	function dispose():Void;
	function hasStencil():Bool;
	function isDepth():Bool;
	/**
		
				Downloads the current texture data from the GPU.
				Beware, this is a very slow operation that shouldn't be done during rendering.
			
	**/
	function capturePixels(?face:Int, ?mipLevel:Int, ?region:h2d.col.IBounds):Dynamic;
	/**
		
				The default texture color format
			
	**/
	static var nativeFormat(default, never) : h3d.mat.Data.TextureFormat;
	static var TRILINEAR_FILTERING_ENABLED : Bool;
	static var DEFAULT_WRAP : h3d.mat.Data.Wrap;
	/**
		
				This will return the default depth buffer, which is automatically resized to the screen size.
			
	**/
	static function getDefaultDepth():h3d.mat.Texture;
	static function fromBitmap(bmp:Dynamic):h3d.mat.Texture;
	static function fromPixels(pixels:Dynamic, ?format:h3d.mat.Data.TextureFormat):h3d.mat.Texture;
	/**
		
				Creates a 1x1 texture using the RGB color passed as parameter.
			
	**/
	static function fromColor(color:Int, ?alpha:Float):h3d.mat.Texture;
	static function genDisc(size:Int, color:Int, ?alpha:Float):h3d.mat.Texture;
	/**
		
				Returns a default dummy 1x1 black cube texture
			
	**/
	static function defaultCubeTexture():h3d.mat.Texture;
	/**
		
				Returns a checker texture of size x size, than can be repeated
			
	**/
	static function genChecker(size:Int):h3d.mat.Texture;
	static function genNoise(size:Int):h3d.mat.Texture;
}