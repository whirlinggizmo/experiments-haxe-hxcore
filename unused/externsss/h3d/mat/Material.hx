package h3d.mat;

@:native("h3d.mat.Material") extern class Material extends h3d.mat.BaseMaterial {
	var model : hxd.res.Resource;
	var shadows(get, set) : Bool;
	var castShadows(default, set) : Bool;
	var receiveShadows(default, set) : Bool;
	var staticShadows(default, set) : Bool;
	var textureShader(default, null) : h3d.shader.Texture;
	var specularShader(default, null) : h3d.shader.SpecularTexture;
	var texture(get, set) : h3d.mat.Texture;
	var specularTexture(get, set) : h3d.mat.Texture;
	var normalMap(get, set) : h3d.mat.Texture;
	var color(get, set) : h3d.Vector4;
	var specularAmount(get, set) : Float;
	var specularPower(get, set) : Float;
	var blendMode(default, set) : h3d.mat.BlendMode;
	private function set_castShadows(v:Bool):Bool;
	private function set_receiveShadows(v:Bool):Bool;
	private function set_staticShadows(v:Bool):Bool;
	override function clone(?m:h3d.mat.BaseMaterial):h3d.mat.BaseMaterial;
	private function set_blendMode(v:h3d.mat.BlendMode):h3d.mat.BlendMode;
	private function get_specularTexture():h3d.mat.Texture;
	private function get_texture():h3d.mat.Texture;
	private function set_texture(t:h3d.mat.Texture):h3d.mat.Texture;
	private function get_normalMap():h3d.mat.Texture;
	private function set_normalMap(t:h3d.mat.Texture):h3d.mat.Texture;
	private function set_specularTexture(t:h3d.mat.Texture):h3d.mat.Texture;
	function getDefaultModelProps():Any;
	override function getDefaultProps(?type:String):Any;
	override function refreshProps():Void;
	static function create(?tex:h3d.mat.Texture):h3d.mat.Material;
}