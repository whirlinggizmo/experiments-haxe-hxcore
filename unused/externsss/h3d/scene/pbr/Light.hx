package h3d.scene.pbr;

@:native("h3d.scene.pbr.Light") extern class Light extends h3d.scene.Light {
	var power : Float;
	var shadows : h3d.pass.Shadows;
	var isMainLight : Bool;
	var occlusionFactor : Float;
	var enableForward : Bool;
}