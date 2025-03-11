package h3d.prim;

typedef HideProps = {
	var animations : haxe.DynamicAccess<{ public var events(default, default) : Array<{ public var frame(default, default) : Int; public var data(default, default) : String; }>; }>;
};

@:native("h3d.prim.ModelCache") extern class ModelCache {
	function new():Void;
	function dispose():Void;
	function loadLibrary(res:hxd.res.Model):hxd.fmt.hmd.Library;
	function loadModel(res:hxd.res.Model):h3d.scene.Object;
	function loadCollider(res:hxd.res.Model):Array<h3d.col.TransformCollider>;
	function loadTexture(model:hxd.res.Model, texturePath:String, ?async:Bool):h3d.mat.Texture;
	function loadAnimation(anim:hxd.res.Model, ?name:String, ?forModel:hxd.res.Model):h3d.anim.Animation;
	function cleanModels(?lastUseTime:Int):Void;
}