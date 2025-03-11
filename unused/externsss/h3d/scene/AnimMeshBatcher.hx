package h3d.scene;

@:src({
		@param var animationMatrix:Mat4;
		@global var global:{ @perObject
		var modelView : Mat4; };
		@input var input:{ var normal : Vec3; };
		var relativePosition:Vec3;
		var transformedNormal:Vec3;
		function vertex() {
			relativePosition = relativePosition * animationMatrix.mat3x4();
			transformedNormal = (input.normal * animationMatrix.mat3() * global.modelView.mat3()).normalize();
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.AnimMeshBatcher") extern class AnimMeshBatchShader extends hxsl.Shader {
	function new():Void;
	var animationMatrix(get, set) : hxsl.Types.Matrix;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function setParamIndexValue(index:Int, val:Dynamic):Void;
	override function setParamIndexFloatValue(index:Int, val:Float):Void;
	override function clone():hxsl.Shader;
}

@:native("h3d.scene.AnimMeshBatcher") extern class AnimMeshBatch extends h3d.scene.MeshBatch {
	function new(primitive:h3d.prim.MeshPrimitive, material:h3d.mat.Material, copyObject:h3d.scene.Object, ?parent:h3d.scene.Object):Void;
}

@:native("h3d.scene.AnimMeshBatcher") extern class AnimMeshBatcher extends h3d.scene.Object {
	function new(object:h3d.scene.Object, spawn:h3d.Matrix -> Bool, ?parent:h3d.scene.Object):Void;
	override function playAnimation(anim:h3d.anim.Animation):h3d.anim.Animation;
}